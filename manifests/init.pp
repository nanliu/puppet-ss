# Secretserver class
# This just sets the required parameters.
class ss {
	# Make sure the puppet master has access to the secretserver, and
	# the username can log in with a password (and not two-factor if
	# you use that)

	# Secretserver host
        $ss_hostname = 'secretserver.auckland.ac.nz'
	# Secretserver login information
	# This username must have read/write access to all the secrets
	# you wish to manage with puppet
        $ss_username = 'puppet'
        $ss_password = 'secretpassword'
        # where to create them by default
	# This folder must exist, and have read/write access to the 
	# puppet username.
        $ss_folder   = 'Drop-box'
	
	# Defaults
	$password_length = 10
}
