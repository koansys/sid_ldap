==========
 SID LDAP
==========

Vagrant
=======

We use Vagrant to create a CentOS VM and install LDAP, Apache, Trac,
SVN, etc.

To create from scratch::

  vagrant up

To re-provision::

  vagrant provision

To destroy the VM so you can create a fresh one::

  vagrant destroy

You can get to the VM from this directory with::

  vagrant ssh

Vagrant creates a proxy so you can get to the VMs web server at:

  http://localhost:65080/
  http://localhost:65080/trac/project1

Puppet
======

Vagrant uses Puppet to install software and configure the system. The
config file is in manifests/sid_ldap.pp.

After Vagrant runs, it mounts this file on the VM so you can invoke it
there, verbosely, with::

  vagrant ssh
  sudo puppet apply -v /tmp/vagrant-puppet/manifests/sid_ldap.pp

Any changes to the file you make on the VM are made to the file here
since it's a vbox mount, acting much like NFS.

Yum Problem
===========

On 2011-09-26 the Puppet install failed, due repo specs that were not
found. It appears /etc/yum.repos.d/elff.repo and its cache in
/var/cache/yum/elff.  They reference a server
download.elff.bravenet.com which appears to prefer to be called
download.bravehost.com.  Work around this by moving the repo spec and
removing the cache in the Puppet manifest.
