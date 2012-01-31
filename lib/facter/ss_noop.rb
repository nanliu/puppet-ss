Facter.add('ss_noop') do
  setcode do
    Puppet[:noop]
  end
end
