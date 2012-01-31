# Usage:
# ss::cert { 'list.auckland.ac.nz': }
#
# use key=> and crt=> to define cert file location if not in /etc/httpd/conf
# use service=>false if you dont want it to restart httpd if cert changes
# use ss=>false if you want it to pull from a file instead of secretserver

define ss::cert($key='',$crt='',$service=true,$ss=true) {
  include ss
  if $key {
    $keyfile = $key
  } else {
    $keyfile = "/etc/httpd/conf/$name.key"
  }
  if $crt {
    $crtfile = $crt
  } else {
    $crtfile = "/etc/httpd/conf/$name.crt"
  }
  if $ss {
    $certificate = ss_fetch_cert($name,$ss::ss_username,$ss::ss_password,$ss::ss_hostname)
    $privatekey  = ss_fetch_key($name,$ss::ss_username,$ss::ss_password,$ss::ss_hostname)
  } else {
    $certificate = file(
      "/etc/puppet/$environment/modules/ss/files/${name}.crt",
      "/etc/puppet/$environment/files/ss/${name}.crt",
      "/etc/puppet/$environment/files/${name}.crt"
    )
    $privatekey = file(
      "/etc/puppet/$environment/modules/ss/files/${name}.key",
      "/etc/puppet/$environment/files/ss/${name}.key",
      "/etc/puppet/$environment/files/${name}.key"
    )
  }
  if $certificate {
    if $service {
      if ! defined( Service[httpd] ) {
        service { 'httpd': 
          hasstatus=>true, hasrestart=>true,
          ensure=>running, enable=>true;
        }
      }
      $refreshsvc = [ Service[httpd] ]
    } else {
      $refreshsvc = [ ]
    }
    file {
      $keyfile: content=>$privatekey, 
        notify=>$refreshsvc,
        owner=>root, group=>root, mode=>0640;
      $crtfile: content=>$certificate, 
        notify=>$refreshsvc,
        owner=>root, group=>root, mode=>0640;
    }
  } else {
    notify { "certerror-$name": withpath=>false,
      message=>"ERROR: No certificate found for $name";
    }
  }
}
