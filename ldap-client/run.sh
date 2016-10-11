#!/bin/bash

cp -R /etc /gen/etc5/etc

authconfig --enableshadow --enablemkhomedir --enableldap --enableldapauth --ldapserver=$LDAP_SERVER --ldapbasedn=$LDAP_BASEDN --update

cp -R /etc /gen/etc5/etcnew

diff -u -r -x passwd -x group -x shadow /gen/etc5/etc /gen/etc5/etcnew > /gen/client.diff || true

rm -rf /gen/etc5/etc
rm -rf /gen/etc5/etcnew

getent passwd username

/usr/share/openldap/migration/migrate_passwd.pl /etc/passwd > /gen/passwd.ldif

/usr/share/openldap/migration/migrate_group.pl /etc/group > /gen/group.ldif
