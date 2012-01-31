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
define ss::password (
  $username    = $name, # namevar
  $max_age     = hiera('ss_max_age', 30),
  $minreset    = hiera('ss_minreset', 0),
  $debug       = hiera('ss_debug', false),
  # defaults provided in ss::data
  $folder      = hiera('ss_folder'),
  $ss_username = hiera('ss_username'),
  $ss_password = hiera('ss_password'),
  $ss_hostname = hiera('ss_hostname')
) {
  $account_age = ss_passwd_age($username)
  $ss_exists = ss_check($username, $::fqdn, $ss_username, $ss_password, $ss_hostname)
  if $debug {
    notice ( "ss::password: ${username} password age ${age_account} days, SS account record ${ss_exists}" )
  }
  if $account_age > $max_age or $ss_exists == 'false' {
    $newpass = ss_gen_passwd($password_length)
    if $debug {
      notice( "Updating password for ${username} on ${::fqdn}" )
    }

    # change password for account
    exec { "passwd_$name":
      command => $::osfamily ?{
        # RedHat allows /usr/bin/passwd --stdin, but all
        # allow use of /usr/sbin/chpasswd
        # Solaris needs chpasswd to be installed but then it
        # works OK.  AIX, no idea...
        'RedHat'  => "/usr/bin/chage -m '$minreset' '$username';/bin/echo '$username:$newpass'|/usr/sbin/chpasswd",
        'Debian'  => "/usr/bin/chage -m '$minreset' '$username';/bin/echo '$username:$newpass'|/usr/sbin/chpasswd",
        'Solaris' => "/bin/echo '$username:$newpass'|/usr/sbin/chpasswd",
        default   => '/bin/false',
      },
      onlyif=>"/bin/egrep '^${username}:' /etc/passwd",
    }
    # update secretserver
    if $::ss_noop == "true" {
      notify { "ss::password: ${username}":
        message  => "Not updating SecretServer for ${username} because in --noop mode",
        withpath => false, # This should be by default (???)
      }
    } else {
      $rv = ss_setpass($username, $::fqdn, $newpass, $ss_username, $ss_password, $ss_hostname, $folder)
      if $rv != 'false' {
        notify { "ss::password: ${username}":
          message  => "Error: SecretServer password update FAILED for ${username}@${::fqdn}: ${rv}",
          withpath => false,
        }
        err( $rv )
      } else {
        notify { "ss::password: ${username}":
          message  => "SecretServer password updated for ${username}@${::fqdn}",
          withpath => false,
        }
      }
    }
  }
}

