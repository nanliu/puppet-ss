accounts   = {}
uids       = {}

# Do not remove this line, it load operatingsystem for osfamily
os = Facter.value(:operatingsystem)

# For just the system users
case Facter.value(:osfamily)
when 'RedHat'
  maxuid = 500
when 'Ubuntu'
  maxuid = 1000
when 'Solaris'
  maxuid = 500
else
  maxuid = 500
end
# For all users just set FACTER_ss_all_user = 100000
maxuid = Facter.value(:ss_userlimit) if Facter.value(:ss_userlimit)

File.open("/etc/passwd").each do |line|
  uids[$1] = $2.to_i if line =~ /^([^:\s]+):[^:]+:(\d+):/
end

File.open("/etc/shadow").each do |line|
  username   = nil
  passwd_age = nil
  username = $1 and passwd_age = $2 if line =~ /^([^:\s]+):[^:]+:(\d+):/ && uids[$1] && uids[$1] < maxuid
  if username != nil && passwd_age != nil
    accounts['ss_passwd_age_'+username] =
      ((Time.now-Time.at(passwd_age.to_i*24*3600))/(24*3600)).floor
  end
end

accounts.each do |name, passwd_age|
  Facter.add(name) do
    setcode do
      passwd_age
    end
  end
end
