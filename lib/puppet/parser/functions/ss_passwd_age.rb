# Return the age of the password for the specified user, using the custom facts
module Puppet::Parser::Functions
  newfunction(:ss_passwd_age, :type=>:rvalue) do |args|
    value = lookupvar("::ss_passwd_age_"+args[0]).to_i
    value ||= -1
  end
end
