username   = nil
passwd_age = nil
accounts   = {}
uids       = {}
# For just the system users
case Facter[:osfamily].value
when 'RedHat'
  maxuid = 500
when 'Solaris'
  maxuid = 500
when 'Ubuntu'
  maxuid = 1000
else
  maxuid = 500
end
# For ALL users
# maxuid = 100000

File.open("/etc/passwd").each do |line|
  uids[$1] = $2.to_i if line =~ /^([^:\s]+):[^:]+:(\d+):/
end

File.open("/etc/shadow").each do |line|
  username = $1 and passwd_age = $2 if line =~ /^([^:\s]+):[^:]+:(\d+):/ && uids[$1] && uids[$1] < maxuid
  if username != nil && passwd_age != nil
    accounts['ss_passwd_age_'+username] =
      ((Time.now-Time.at(passwd_age.to_i*24*3600))/(24*3600)).floor
    username   = nil
    passwd_age = nil
  end
end

accounts.each { |name, passwd_age|
  Facter.add(name) do
    setcode do
      pass_age
    end
  end
}
