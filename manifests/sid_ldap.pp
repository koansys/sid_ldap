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
# - run 'facter' on VM to find the facts puppet knows, like ${::operatingsystem}
###############################################################################

# Defaults

Exec { path             => ['/bin', '/usr/bin', '/usr/sbin'] }
Package { ensure        => latest }

# When

stage { "fixrepos": before      => Stage["update"] }
stage { "update": before        => Stage["pre"] }
stage { "pre": before           => Stage["main"] }

# Components

class fixrepos {
  # I don't know where this repo spec came from
  # but Bravenet doesn't have what we need now.
  # We may need an updated VM with a different repo spec.
  # NOTE: THESE DO NOT APPEAR TO BE EXECUTED IN ORDER?
  exec { 'bravenet-hide':
    command     => "mv /etc/yum.repos.d/elff.repo /etc/yum.repos.d/elff.repo.NOTFOUND || echo ELFF.REPO HIDDEN",
  }
  exec { 'bravenet-uncache':
    command     => "rm -rf /var/cache/yum/elff || echo RM_ELFF_REPO_CACHE",
  }
  exec { 'bravenet-ls':
    command     => "ls -al /etc/yum.repos.d/",
  }
}

class rpmupdate {
  # centos/rhel only :-(
  exec { 'rpm_additions':
    # TODO: don't do this if we already did it
    command       => "rpm -Uhv --force http://apt.sw.be/redhat/el5/en/x86_64/rpmforge/RPMS/rpmforge-release-0.5.2-2.el5.rf.x86_64.rpm",
  }
  exec { 'yumupdate':
    command     => "yum update -y",
  }
}

class apache {
  $apache = $operatingsystem ? {
    /(?i)(centos|redhat)/ => 'httpd',
    /(?i)(ubuntu|debian)/ => "apache2",
    default               => undef,
  }
  package { apache:
    name          => $apache,
  }
  package { mod_authz_ldap:
    require     => Class["ldap"]
  }
  # no file /etc/httpd/modules/mod_authz_ldap.so
  service { httpd:
    ensure => running,
  }
}


class emacs {
  $emacs = $operatingsystem ? {
    /(?i)(centos|redhat)/ => 'emacs-nox',
    /(?i)(ubuntu|debian)/ => "emacs-nox11",
    default               => undef,
  }
  package { emacs:
    name          => $emacs,
    ensure        => latest;
  }
}

class ldap {
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
  package { ldapdev:
    name          => $ldapdev,
  }
  package { ldapclients:
    name          => $ldapclients,
  }
  package { ldapservers:
    name          => $ldapservers,
  }
  service { ldap:
    # process is called 'slapd' but we need its /etc/init.d/ldap name
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
  file { 'authz_ldap.conf':
    name          => '/etc/httpd/conf.d/authz_ldap.conf',
    ensure        => present,
    source        => '/vagrant/files/authz_ldap.conf',
    owner         => root,
    group         => root,
    mode          => 0644,
  }
}

# No Centos Trac pkg? "sudo easy_install Trac"?
#package { trac:
  #  ensure => installed;
#}
# clearsilver, trac...
# easy_install trac

class subversion {
  package { subversion:
  }
  package { mod_dav_svn:
    require     => Class["apache"]
  }
}

class python {
  package { python:
    ensure        => latest;
  }
}
class trac {
  # The Trac package uses mod_python and expects instance in /var/trac
  # We adjust the supplied file to use LDAP.
  package { 'trac':
    require     => Class["python"];
  }
  package { 'mod_python':
    require       => [Class["apache"],Class["python"]];
  }
  file { '/etc/httpd/conf.d/trac.conf':
    ensure      => present,
    source      => '/vagrant/files/trac.conf',
    owner       => 'root',
    group       => 'root',
    mode        => '0644',
    }
}

class svn_instance {
  exec { 'mkdir -p /var/svn': }
  exec { 'svnadmin create /var/svn/project1':
    unless      => 'test -d /var/svn/project1',
    require     => Class["subversion"]
  }
  file { '/var/svn/project1/db':
    ensure      => directory,
    owner       => 'apache',
    group       => 'apache',
    mode        => '0664',
    recurse     => true,
  }
}

class trac_instance {
  exec { 'mkdir -p /var/trac': }
  exec { 'trac_create_project1':
    command     => "trac-admin /var/trac/project1 initenv 'Project 1' sqlite:db/trac.db svn /var/svn/project1",
    unless      => 'test -d /var/trac/project1',
    require     => [Class["trac"],Class["svn_instance"]],
  }
  # Seems 'file' is run before 'exec' so separate out the permisisons??
}

class trac_permissions {
  file { '/var/trac/project1/db':
    ensure      => directory,
    owner       => 'apache',
    group       => 'apache',
    mode        => '0664',
    recurse     => true,
    require     => Class["trac_instance"],
  }
  file { '/var/trac/project1/attachments':
    ensure      => directory,
    owner       => 'apache',
    group       => 'apache',
    mode        => '0664',
    recurse     => true,
    require     => Class["trac_instance"],
  }
}

# class trac_mod_wsgi {
#   file { '/var/trac/trac.wsgi':
#       ensure        => present,
#       source        => '/vagrant/files/trac.wsgi',
#       owner         => root,
#       group         => root,
#       mode          => 0644,
#     }
#   file { '/var/trac/trac.wsgi':
#       ensure        => present,
#       source        => '/vagrant/files/trac.wsgi',
#       owner         => root,
#       group         => root,
#       mode          => 0644,
#     }
# }
  
# something hosed in the puppet indentation here:

exec { 'ldapaddusers':
  # Add initial organization and test users.
  # I believe we need to run as root to use 'slapcat'.
  # TODO: require service ldap/slapd
  command       => "ldapadd -x -D 'cn=manager,dc=example,dc=gov' -w password -f /vagrant/files/users.ldif",
  cwd           => "/vagrant/files",
  logoutput     => true,
  unless        => ['ldapsearch -x -b ou=people,dc=example,dc=gov ou=People | grep "dn: ou=People,dc=example,dc=gov"',
                    'ldapsearch -x -b ou=people,dc=example,dc=gov uid=user1 | grep "dn: uid=user1,ou=People,dc=example,dc=gov"',
                    'ldapsearch -x -b ou=people,dc=example,dc=gov uid=user2 | grep "dn: uid=user1,ou=People,dc=example,dc=gov"'
                    ];
                  }

class { "fixrepos":     stage => "fixrepos" }
class { "rpmupdate":    stage => "update" }
class { "python":       stage => "pre" }
class { "emacs":        stage => "pre" } # not really needed anywhere special

class sid {
  include fixrepos
  include rpmupdate
  include apache
  include emacs
  include ldap
  include subversion
  include python
  include trac
  include svn_instance
  include trac_instance
  include trac_permissions
}

include sid

