# Change password if older than 30 days, updating secret server
# This will also change andupdate is password is not yet defined on SecretSvr
# It will NOT verify that SS record contains the correct password though as
# this is not necessarily possible with various backends
# Only users with UID<500 are checked; to change this, edit the facter module
# to set facts for ALL users.
#
# Facter should set facts: pwage_(.*) for all accounts <500
#
# To use:
#    $ss_hostname = 'secretserver.auckland.ac.nz'
#    $ss_username = 'puppet'
#    $ss_password = 'mypassword'
#    $ss_folder   = 'Drop-box'
#    class { password: username=> 'root', }
#    class { password: username=>'oracle', maxage=>60, 
#                      folder=>'Oracle Passwords' }
#
# Assumptions:
#    1. The specified user exists as a Local user with no 2FA rules
#    2. The specified folder exists, is writeable, and defaults to appropriate
#       sharing rules
#    3. All passwords for servers are shared with the puppet user
#    4. All newly created passwords will be with 'Unix Account (SSH)' template
#    5. Passwords can be changed via "echo 'pass'|passwd --stdin username"
#       This is true under RedHat but not necessarily elsewhere.
#    6. Password ages are in /etc/shadow in standard format
#
# Bugs:
#    1. No way to detect noop mode from functions, therefore secret server is
#       updated even if we are in noop mode and will not actually change the 
#       password on the client!

# This adds a new username to check for expiry
define password($maxage=30,$username='',$folder='',$minreset=0) {
	include ss
	if $username == '' {
		$uname = $name
	} else {
		$uname = $username
	}
	if $folder == '' {
		$cfolder = $ss::ss_folder
	} else {
		$cfolder = $folder
	}
	$age_account = password_age($uname)
	$ssexists = ss_check($uname,$fqdn,
	  	  $ss::ss_username,$ss::ss_password,$ss::ss_hostname)
	notice ( "Password for $uname has age of $age_account : SS record $ssexists" )
	if $age_account > $maxage or $ssexists == 'false' {
		$newpass = generate_password($password_length)
		notice( "Updating password for $uname on $fqdn" )
		# change password for account
                exec { "passwd_$name":
                  command=>$operatingsystem?{
                        # RedHat allows /usr/bin/passwd --stdin, but all
                        # allow use of /usr/sbin/chpasswd
                        # Solaris needs chpasswd to be installed but then it
                        # works OK.  AIX, no idea...
                        /(RedHat|CentOS|Fedora)/=>"/usr/bin/chage -m '$minreset' '$uname';/bin/echo '$uname:$newpass'|/usr/sbin/chpasswd",
                        /(Ubuntu|Debian)/       =>"/usr/bin/chage -m '$minreset' '$uname';/bin/echo '$uname:$newpass'|/usr/sbin/chpasswd",
                        /(Solaris|SunOS)/       =>"/bin/echo '$uname:$newpass'|/usr/sbin/chpasswd",
                        default=>"/bin/false",
                  },
                  onlyif=>"/bin/egrep '^$uname:' /etc/passwd",
                }
		# update secretserver
		# The $noop test DOES NOT WORK in puppet 2.7
		if $noop {
		  notify { "ss-secret-$uname": withpath=>false,
		    message=>"Not updating SecretServer for $uname because in --noop mode" }
		} else {
		  $rv = ss_setpass($uname,$fqdn,$newpass,
	  	    $ss::ss_username,$ss::ss_password,$ss::ss_hostname,$cfolder)
		  if $rv != 'false' {
		    notify { "ss-secret-$uname": withpath=>false,
		      message=>"ERROR: SecretServer password update FAILED for $uname@$fqdn: $rv" }
		    err( $rv )
		  } else {
		    notify { "ss-secret-$uname": withpath=>false,
		      message=>"SecretServer password updated for $uname@$fqdn" }
		  }
		}
	}
}

