require 'puppet/util/secretserver'

module Puppet::Parser::Functions

# This should check the password in SecretServer

  newfunction(:ss_check,:type=>:rvalue) do |args|
    itemusername = args[0]
    itemhostname = args[1]
    ssuser       = args[2]
    sspassword   = args[3]
    sshostname   = args[4]

    Savon.configure do |config|
      config.log          = false            # disable logging
      config.log_level    = :error     # changing the log level
      config.raise_errors = false
    end
    HTTPI.log = false

    # Establish session
    begin
      ss = SecretServer.new(sshostname, "secretserver", ssuser, sspassword, '', 'Local' )
    rescue Exception => e
      return 'unknown: rescued #{e.message}'
    end

    # Seek the item
    begin
      dunnit = 0
      s = ss.search( itemusername+'@'+itemhostname )
      if s.size == 0
        return 'false'
      else
        s.each {|r|
          x = ss.get_secret(r)
          if ( x.secret[:name] == ( itemusername+'@'+itemhostname) ) 
            dunnit = 1
          end
        }
        if dunnit
          return 'true'
        end
        return 'false'
      end
    rescue
      return "Unknown: ERROR: #{$!}"
    end
    return 'unknown'
  end # function
end # module
