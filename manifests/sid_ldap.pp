# -*- puppet -*-
# Want trac, httpd, ldap.
# later various ldap apache modules, configs

# TODO:
# - wrap in platform specific class, like "class lucid32 {..."
# - use SSL cert for LDAPS
# - use client's real basedn
# - see for parametric trac config generation: http://docs.puppetlabs.com/guides/templating.html
# - mod_auth_ldap: mod_authz_ldap for yum in Centos
# - Apache conf with auth to mod_auth_ldap
# - restricted page requring auth
#
# NOTES:
# - create rootpw with 'slappasswd'
# - create users and passwords with ... what?
###############################################################################


# Run 'facter' on VM to find the facts puppet knows; samples:
file { vars:
  ensure => file,
  path => "/tmp/vars",
  mode => 0644,
  content => "hostname=${::hostname} operatingsystem=${::operatingsystem} fqdn=${::fqdn} domain=${::domain} ipaddress=${::ipaddress}",
}

$apache = $operatingsystem ? {
  /(?i)(centos|redhat)/ => 'httpd',
  /(?i)(ubuntu|debian)/ => "apache2",
  default               => undef,
}

$emacs = $operatingsystem ? {
  /(?i)(centos|redhat)/ => 'emacs-nox',
  /(?i)(ubuntu|debian)/ => "emacs-nox11",
  default               => undef,
}

$ldapdev = $operatingsystem ? {
  /(?i)(centos|redhat)/ => 'openldap-devel',
  /(?i)(ubuntu|debian)/ => "openldap-devel",
  default               => undef,
}

$ldapclients = $operatingsystem ? {
  /(?i)(centos|redhat)/ => 'openldap-clients',
  /(?i)(ubuntu|debian)/ => "openldap-clients",
  default               => undef,
}

$ldapservers = $operatingsystem ? {
  /(?i)(centos|redhat)/ => 'openldap-servers',
  /(?i)(ubuntu|debian)/ => "openldap-servers",
  default               => undef,
}

package { apache:
  name          => $apache,
  ensure        => latest;
}

package { emacs:
  name          => $emacs,
  ensure        => latest;
}

package { ldapdev:
  name          => $ldapdev,
  ensure        => latest;
}

package { ldapclients:
  name          => $ldapclients,
  ensure        => latest;
}

package { ldapservers:
  name          => $ldapservers,
  ensure        => latest;
}

package { mod_authz_ldap:
  ensure        => latest;
}

# No Centos Trac pkg? "sudo easy_install Trac"?
#package { trac:
#  ensure => installed;
#}

service { httpd:
  ensure => running,
}

# process is called 'slapd' but we need its /etc/init.d/ldap name
service { ldap:
  ensure        => running,
  enable        => true,
  subscribe     => File['slapd.conf']
}

# Centos runs this as user 'ldap' group 'ldap'
# The source relies on Vagrant mounting its dir on target as /vagrant.
file { 'slapd.conf':
  name          => '/etc/openldap/slapd.conf',
  ensure        => present,
  source        => '/vagrant/files/slapd.conf',
  owner         => root,
  group         => ldap,
  mode          => 0640,
}

# Add initial organization and test users.
# I believe we need to run as root to use 'slapcat'.
# TODO: require service ldap/slapd

exec { 'ldapaddusers':
  path          => ['/bin', '/usr/bin', '/usr/sbin'],
  command       => "ldapadd -x -D 'cn=manager,dc=example,dc=gov' -w password -f /vagrant/files/users.ldif",
  cwd           => "/vagrant/files",
  logoutput     => true,
  unless        => ['slapcat | grep "dn: ou=People,dc=example,dc=gov"',
                    'slapcat | grep "dn: uid=user1,ou=People,dc=example,dc=gov"',
                    'slapcat | grep "dn: uid=user1,ou=People,dc=example,dc=gov"',
                    ],
}
