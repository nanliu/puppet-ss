MANIFESTS=manifests/cert.pp manifests/init.pp manifests/password.pp
PLUGINS=lib/puppet/parser/functions/ss_fetch_key.rb lib/puppet/parser/functions/password_age.rb lib/puppet/parser/functions/ss_fetch_cert.rb lib/puppet/parser/functions/ss_setpass.rb lib/puppet/parser/functions/ss_check.rb lib/puppet/parser/functions/generate_password.rb lib/facter/passwords.rb

all: $(MANIFESTS) $(PLUGINS) secretserver.rb
	@puppet-module build
	@echo Done
