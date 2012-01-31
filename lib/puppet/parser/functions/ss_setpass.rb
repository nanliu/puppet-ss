require "secretserver"
require 'puppet'

module Puppet::Parser::Functions

# This should set the password in SecretServer

  newfunction(:ss_setpass,:type=>:rvalue) do |args|
	itemusername = args[0]
	itemhostname = args[1]
	newpass    = args[2]
	ssuser     = args[3]
	sspassword = args[4]
	sshostname = args[5]
	foldername = args[6]
	templatename = 'Unix Account (SSH)' # Secret type for creates
	if foldername = ''
		foldername = 'Drop-box' # Folder for creates (cannot be blank)
	end

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
	  return "Login to Secret Server failed!"
	end
	
	if Puppet[:noop] 
	  return "SecretServer NOT updated as in --noop mode"
	end

	# Seek the item
	dunnit = 0
	s = ss.search( itemusername+'@'+itemhostname )
	if s.size == 0
	  begin
	    ss.set_password( itemusername+'@'+itemhostname, 
	      foldername, templatename,
              {'Username'=>itemusername, 'Machine'=>itemhostname, 
	        'Password'=>newpass })
	  rescue
		return "There was a create error: #{$!}"
	  else
		dunnit = 1
	  end
	elsif s.size == 1
	  begin
	  	x = ss.get_secret(s[0])
		x.secret[:items][:secret_item].each { |secretitem|
			if secretitem[:is_password]  
				secretitem[:value] = newpass 
			end
		}
  		ss.update_secret(x)
	  rescue
		return "There was an update error: #{$!}"
	  else
		dunnit = 1
	  end
	else
	  begin
	  s.each {|r|
		x = ss.get_secret(r)
		if ( x.secret[:name] == (itemusername+'@'+itemhostname) ) 
			x.secret[:items][:secret_item].each { |i|
				if i[:is_password]  
					i[:value] = newpass 
				end
			}
 		 	ss.update_secret(x)
			dunnit = 1
		end
  	  }
	  rescue
		return "There was a multi update error: #{$!}"
	  end
	  if dunnit  == 0
#	    return "Unable to identify the secret uniquely"
            begin
              ss.set_password( itemusername+'@'+itemhostname,
              foldername, templatename,
              {'Username'=>itemusername, 'Machine'=>itemhostname,
                'Password'=>newpass })
            rescue
                return "There was a create error: #{$!}"
            else
                dunnit = 1
            end
	  end # could not update uniquely: so create new one
	end
	if dunnit == 1
	  return "false"
	else
	  return "SecretServer update FAILED"
	end
  end
end
