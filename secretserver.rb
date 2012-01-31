require "rubygems"
require "savon"
require "base64"

class SecretServer
  attr_reader :error, :result, :templates, :folders

  class Secret
    attr_reader :secret

    def initialize( s )
      @secret = s
    end

    def update( what)
      @secret[:items][:secret_item].each do |f|
        if  what[f[:field_name]]
          f[:value] =  what[f[:field_name]]
          what.delete(f[:field_name])
        end
      end
      raise ArgumentError, "field ''#{what.keys.join(',')}' not found in secret" if what.size > 0

    end
    @secret
  end

  class SearchResult

    def initialize(results)
      @search_result = results
    end

    def secret_id
      @search_result[:secret_id]
    end
    def secret_name
      @search_result[:secret_name]
    end
    def secret_type_name
      @search_result[:secret_type_name]
    end

  end


  def initialize ( host, prefix, user, password, organizationCode, domain )

    @folders = {}
    @templates = {}
    (pw, rad) =  password.split(':')

    @client = Savon::Client.new { wsdl.document = "https://#{host}/#{prefix}/webservices/SSWebService.asmx?wsdl" }

    if ! defined? @client
      raise RuntimeError, "Failed to connect to #{host}"
    end

    if rad
      request( 'AuthenticateRADIUS', {:username=>user, :password=> pw,
              :radius_password => rad, :domain => domain,
              :organization_code => organizationCode })
    else
      request( 'Authenticate',  {:username=>user, :password=> pw })

    end

    @token = @result[:token]
  end

  def request ( ws, params )

    params[:token] = @token if defined? @token;
    @resp = @client.request "urn:thesecretserver.com/"+ws do  |soap|
      soap.input = [ ws, { "xmlns" => "urn:thesecretserver.com"} ]
      soap.body = params
    end
    return nil unless @resp;
    @resp = @resp.to_hash
    ws.gsub!(/([a-z])([A-Z])/, '\1_\2')
    ws.downcase!
    if @resp[:fault]
      raise RuntimeError, "SecretServer::Request::#{ws}: #{@resp[:fault]}"
    end
    @result = @resp[(ws+"_response").to_sym][(ws+"_result").to_sym]
    raise RuntimeError, "SecretServer::Request::#{ws}: #{@result[:errors][:string]}" if @errors = @result[:errors]
    @result
  end

  def search( text )
    request('SearchSecrets', {:search_term=>text });
    r = []
    if @result[:secret_summaries]
      if  @result[:secret_summaries][:secret_summary].is_a? Hash
        x = {}
        @result[:secret_summaries][:secret_summary].each {|y|
          x[y[0]] = y[1]
        }
        r << SearchResult.new(x)
      else
        @result[:secret_summaries][:secret_summary].each {|s|
          r << SearchResult.new(s)
        }
      end
    end
    return r
  end

  def get_secret( secret_id )

    if secret_id.class == SecretServer::SearchResult
      secret_id = secret_id.secret_id
    end
    request( "GetSecret", {:secret_id => secret_id} )
    Secret.new(@result[:secret])
  end

  def download ( secret_id, item_id ) 
    if secret_id.class == SecretServer::SearchResult
      secret_id = secret_id.secret_id
    end
    request( "DownloadFileAttachmentByItemId", 
            { :secret_id => secret_id, :secret_item_id => item_id } )

    # do we need to decode from base64bin?
    Base64.decode64(@result[:file_attachment])
  end

  def get_templates
    if @templates.size == 0
      request( "GetSecretTemplates", {} )
      @result[:secret_templates][:secret_template].each {|t|
        @templates[t[:name]] = t
      }
    end
  end

  def update_secret( secret )
    # This is necessary because Thycotic break the SOAP standard
    allitems = [ ]
    #	pp secret
    secret.secret[:items][:secret_item].each { |i|
      allitems.push( {
        "Value" => i[:value],
        "Id" => i[:id],
        "FieldId" => i[:field_id],
        "FieldName" => i[:field_name],
        "IsFile" => i[:is_file],
        "IsNotes" => i[:is_notes],
        "IsPassword" => i[:is_password],
        "FieldDisplayName" => i[:field_display_name],
      } )
    }
    newsecret = {
      "Name" => secret.secret[:name],
      "Id" => secret.secret[:id],
      "SecretTypeId" => secret.secret[:secret_type_id],
      "FolderId" => secret.secret[:folder_id],
      "Items" => { "SecretItem" => allitems }
    }

    request('UpdateSecret', { :secret => newsecret } )
  end

  def generate_password( template_name )
    template = nil
    field_id = nil

    get_templates if @templates.size == 0 
    template = @templates[template_name]
    raise ArgumentError, "Unknown template name '#{template_name}" unless template

    template[:fields][:secret_field].each { |field|
      if field[:is_password]
        field_id = field[:id]
        break
      end
    }

    raise RuntimeError, "Cant find password field in '#{template_name}" unless field_id
    request( "GeneratePassword", {:secret_field_id => field_id} )
    return  @result[:generated_password]
  end

  def get_folders( name )

    return if @folders[name]
    request( "SearchFolders", { :folder_name => name } )
    raise ArgumentError, "Could not find folder '#{name}'" unless @result[:folders]
    @result[:folders].each { |f|
      @folders[f[1][:name]] = f[1];   # cache folders
    }
  end

  def set_password(name, folder, template, params)

    ids = []
    values = []
    fid = -1

    if template.class == String
      get_templates if @templates.size == 0
      raise ArgumentError, "Unknown template '#{template}'" unless @templates[template] 
      template = @templates[template]
    end

    if folder.class == String
      if folder == ''
        fid = -1
      else
        get_folders(folder) unless @folders[folder]
        raise ArgumentError,"Unknown folder '#{folder}'" unless @folders[folder]
        folder = @folders[folder]
        fid = folder[:id]
      end
    end

    template[:fields][:secret_field].each { |field|
      n = params[field[:display_name]]
      ids << field[:id]
      if n
        values << n
        params.delete(field[:display_name])
      else
        values << ''
      end
    }
    raise ArgumentError, "field ''#{params.keys.join(',')}' not found in template" if params.size > 0 

    request( "AddSecret", {
      :secret_type_id     => template[:id],
      :secret_name        => name,
      :folder_id          => fid,
      :secret_field_ids   => { :int    => ids },
      :secret_item_values => { :string => values }
    })
  end

end

