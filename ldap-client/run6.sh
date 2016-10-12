#!/bin/bash

cp -R /etc /gen/etc6/etc

authconfig --enablemkhomedir --enableldap --enableldapauth --ldapserver=$LDAP_SERVER --ldapbasedn=$LDAP_BASEDN --update

echo sudoers_base dc=mercury,dc=febras,dc=net >> /etc/ldap.conf
echo sudoers_debug 0 >> /etc/ldap.conf

cp -R /etc /gen/etc6/etcnew

diff -u -r /gen/etc6/etc /gen/etc6/etcnew > /gen/client6.diff || true

rm -rf /gen/etc6/etc
rm -rf /gen/etc6/etcnew

getent passwd username

# do not need migrate centos 6 users
# /usr/share/migrationtools/migrate_passwd.pl /etc/passwd > /gen/passwd6.ldif
# /usr/share/migrationtools/migrate_group.pl /etc/group > /gen/group6.ldif
