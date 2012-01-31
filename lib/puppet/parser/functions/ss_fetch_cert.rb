require "secretserver"

module Puppet::Parser::Functions

  newfunction(:ss_fetch_cert,:type=>:rvalue) do |args|
	itemhostname = args[0]
	ssuser     = args[1]
	sspassword = args[2]
	sshostname = args[3]

	Savon.configure do |config|
	  config.log = false            # disable logging
	  config.log_level = :error     # changing the log level
	  config.raise_errors = false
	end
	HTTPI.log = false

	# Establish session
	begin
	  ss = SecretServer.new(sshostname, "secretserver", 
	    ssuser, sspassword, '', 'Local' )
	rescue
	  return ''
	end
	
	# Seek the item
	s = ss.search( itemhostname )
	if s.size == 0
	  return ''
	else
          certificate = ''
          s.each {|r|
            if ( r.secret_name == itemhostname ) and ( r.secret_type_name == 'Certificate' )
              x = ss.get_secret(r)
              itemid = 0
              x.secret[:items][:secret_item].each { |si|
                itemid = si[:id] if si[:field_name] == 'Certificate'
              }
              certificate = ss.download(r,itemid)
              certificate = 'Located but not retrieved' if ! certificate
            end
          }
          return certificate
	end
	return ''
  end
end
