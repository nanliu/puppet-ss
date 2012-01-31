username = nil
pwage = nil
test = {}
uids = {}
# For just the system users
maxuid = 500
# For ALL users
maxuid = 100000

File.open("/etc/passwd").each do |line|
    uids[$1] = $2.to_i if line =~ /^([^:\s]+):[^:]+:(\d+):/
end

File.open("/etc/shadow").each do |line|
    username = $1 and pwage = $2 if line =~ /^([^:\s]+):[^:]+:(\d+):/ && uids[$1] && uids[$1] < maxuid
    if username != nil && pwage != nil
	test['pwage_'+username] = 
		((Time.now-Time.at(pwage.to_i*24*3600))/(24*3600)).floor
	username = nil
	pwage = nil
    end
end

test.each { |name,age|
	Facter.add(name) do
		setcode do
			age
		end
	end
}

