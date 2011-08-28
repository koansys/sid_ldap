# -*- puppet -*-
# Want trac, httpd, ldap.
# later various ldap apache modules, configs

# TODO: wrap in "class lucid32" equivalent.

package { httpd:
        ensure => latest;
}

package { trac:
        ensure => installed;
}

package { "emacs-nox":
  ensure => latest;
}
service { httpd:
        ensure => running,
}

