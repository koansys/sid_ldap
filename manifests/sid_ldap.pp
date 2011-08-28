# -*- puppet -*-
# Want trac, httpd, ldap.
# later various ldap apache modules, configs

# TODO: wrap in "class lucid32" equivalent.

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


# No Centos Trac pkg? "sudo easy_install Trac"?
#package { trac:
#  ensure => installed;
#}

service { httpd:
  ensure => running,
}

