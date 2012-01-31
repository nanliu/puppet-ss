# Class: ss::data
#
# This just sets the required parameters.
# Make sure the puppet master has access to the secretserver, and
# the username can log in with a password (and not two-factor if
# you use that)

# Secretserver host
# Secretserver login information
# This username must have read/write access to all the secrets
# you wish to manage with puppet
      # where to create them by default
# This folder must exist, and have read/write access to the 
# puppet username.
class ss::data {
  $ss_hostname     = hiera('ss_hostname', 'ss.puppetlabs.lan')
  $ss_username     = hiera('ss_username', 'puppet')
  $ss_password     = hiera('ss_password', 'secretpassword')
  $ss_folder       = hiera('ss_folder', 'Drop-box')
  $password_length = hiera('ss_password_length', 10)
}
