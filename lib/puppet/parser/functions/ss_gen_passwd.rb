# Generate a sufficiently random string to use as a password
module Puppet::Parser::Functions
  newfunction(:ss_gen_passwd, :type=>:rvalue) do |args|
    # Minimum password length 10
    length     = args[0].to_i
    passwd_len = length < 10 ? 10 : length

    char       = [('a'..'z'),('A'..'Z')].map{|i| i.to_a}.flatten
    password   = (0..passwd_len).map{ char[rand(char.length)] }.join
  end
end
