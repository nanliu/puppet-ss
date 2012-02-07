# Define: ss::cert
#
# This resource manages webserver certificates via Secret Server.
#
# Parameters:
#
#  key: the cert key file path.
#  crt: the cert file path.
#  service: whether to include apache service.
#  ss: whether to use secret server.
#  username: secret server username.
#  password: secret server password.
#  hostname: secret server hostname.
#
# Requires: Puppet 2.6.5+, Hiera
#
# Sample Usage:
#
#   ss::cert { 'list.auckland.ac.nz': }
#
define ss::cert(
  $key         = "/etc/httpd/conf/${name}.key",
  $crt         = "/etc/httpd/conf/${name}.crt",
  $service     = true,
  $ss          = true,
  $ss_username = hiera('ss_username'),
  $ss_password = hiera('ss_password'),
  $ss_hostname = hiera('ss_hostname')
) {

  if $ss {
    $certificate = ss_fetch_cert($name, $ss_username, $ss_password, $ss_hostname)
    $privatekey  = ss_fetch_key($name, $ss_username, $ss_password, $ss_hostname)
  } else {
    $certificate = file(
      "/etc/puppet/${environment}/modules/ss/files/${name}.crt",
      "/etc/puppet/${environment}/files/ss/${name}.crt",
      "/etc/puppet/${environment}/files/${name}.crt"
    )
    $privatekey = file(
      "/etc/puppet/${environment}/modules/ss/files/${name}.key",
      "/etc/puppet/${environment}/files/ss/${name}.key",
      "/etc/puppet/${environment}/files/${name}.key"
    )
  }
  if $certificate {
    if $service {
      if ! defined( Service[httpd] ) {
        service { 'httpd':
          ensure     => running,
          enable     => true,
          hasstatus  => true,
          hasrestart => true,
        }
      }
      $refreshsvc = [ Service[httpd] ]
    } else {
      $refreshsvc = undef
    }
    file { $keyfile:
      content => $privatekey,
      owner   => '0',
      group   => '0',
      mode    => '0640',
      notify  => $refreshsvc,
    }

    file {  $crtfile:
      content => $certificate,
      owner   => '0',
      group   => '0',
      mode    => '0640',
      notify  => $refreshsvc,
    }
  } else {
    notify { "ss::cert: $name":
      message  => "ERROR: No certificate found for $name",
      withpath => false,
    }
  }

}
