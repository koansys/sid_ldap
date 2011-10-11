# -*- ruby -*-
# Create CentOS RedHat-like box with LDAP, Apache, Trac to test LDAP auth for Trac.
# After creation my local filesystem has some mounts on the vbox:
# - v-root on /vagrant type vboxsf (uid=500,gid=501,rw)
# - manifests on /tmp/vagrant-puppet/manifests type vboxsf (uid=500,gid=501,rw)
# so you can edit here and they're reflected there; cool!

Vagrant::Config.run do |config|
  config.vm.box = "vagrant-0.7-centos-64-base.box"

  config.vm.box_url = "http://dl.dropbox.com/u/15307300/vagrant-0.7-centos-64-base.box"

  # Use "vagrant ssh" instead so you get a decent terminal.
  # config.vm.boot_mode = :gui

  # Assign this VM to a host only network IP, allowing you to access it
  # via the IP.
  # config.vm.network "33.33.33.10"

  # Forward a port from the guest to the host, which allows for outside
  # computers to access the VM, whereas host only networking does not.
  config.vm.forward_port "http", 80, 65080

  # Share an additional folder to the guest VM. The first argument is
  # an identifier, the second is the path on the guest to mount the
  # folder, and the third is the path on the host to the actual folder.
  # config.vm.share_folder "v-data", "/vagrant_data", "../data"

  # Enable provisioning with Puppet stand alone.

  config.vm.provision :puppet do |puppet|
    puppet.manifests_path = "manifests"
    puppet.manifest_file  = "sid_ldap.pp"
    puppet.options        = "--verbose --debug"
  end

end
