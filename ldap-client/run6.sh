#!/bin/bash

authconfig --enablemkhomedir --enableldap --enableldapauth --ldapserver=$LDAP_SERVER --ldapbasedn=$LDAP_BASEDN --update

getent passwd username

/usr/share/migrationtools/migrate_passwd.pl /etc/passwd || true
