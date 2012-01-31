module Puppet::Parser::Functions

# Return the age of the password for the specified user, using the custom facts

  newfunction(:password_age,:type=>:rvalue) do |args|
	v = lookupvar("pwage_"+args[0])
	v = -1 if(v == nil)
	v.to_i
  end
end
