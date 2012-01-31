module Puppet::Parser::Functions

# Generate a sufficiently random string to use as a password

  newfunction(:generate_password,:type=>:rvalue) do |args|
    pwlen = args[0]
    if pwlen then
      pwlen = 10 if(pwlen < 8)
    else
      pwlen = 10
    end
    pass = rand.to_s  + $$.to_s + Time.now.to_s 
    pass.crypt(Time.now.sec.to_s*2)[-pwlen,pwlen]
  end
end
