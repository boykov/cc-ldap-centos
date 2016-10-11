#!/bin/bash

cp -R /etc /gen/etc6/etc

authconfig --enablemkhomedir --enableldap --enableldapauth --ldapserver=$LDAP_SERVER --ldapbasedn=$LDAP_BASEDN --update

cp -R /etc /gen/etc6/etcnew

diff -u -r /gen/etc6/etc /gen/etc6/etcnew > /gen/client6.diff || true

rm -rf /gen/etc6/etc
rm -rf /gen/etc6/etcnew

getent passwd username

/usr/share/migrationtools/migrate_passwd.pl /etc/passwd || true
