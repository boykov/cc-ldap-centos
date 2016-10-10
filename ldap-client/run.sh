#!/bin/bash

cp /etc/group /gen/etc5.original/group
cp /etc/group- /gen/etc5.original/group-
cp /etc/ldap.conf /gen/etc5.original/ldap.conf
cp /etc/nsswitch.conf /gen/etc5.original/nsswitch.conf
cp /etc/openldap/ldap.conf /gen/etc5.original/openldap-ldap.conf
cp /etc/pam.d/system-auth /gen/etc5.original/system-auth
cp /etc/passwd /gen/etc5.original/passwd
cp /etc/passwd- /gen/etc5.original/passwd-
cp /etc/sysconfig/authconfig /gen/etc5.original/authconfig

authconfig --enableshadow --enablemkhomedir --enableldap --enableldapauth --ldapserver=$LDAP_SERVER --ldapbasedn=$LDAP_BASEDN --update

cp /etc/group /gen/etc5/group
cp /etc/group- /gen/etc5/group-
cp /etc/gshadow /gen/etc5/gshadow
cp /etc/ldap.conf /gen/etc5/ldap.conf
cp /etc/nsswitch.conf /gen/etc5/nsswitch.conf
cp /etc/openldap/ldap.conf /gen/etc5/openldap-ldap.conf
cp /etc/pam.d/system-auth /gen/etc5/system-auth
cp /etc/passwd /gen/etc5/passwd
cp /etc/passwd- /gen/etc5/passwd-
cp /etc/shadow /gen/etc5/shadow
cp /etc/sysconfig/authconfig /gen/etc5/authconfig

diff -u /gen/etc5.original/ldap.conf /gen/etc5/ldap.conf > /gen/client.diff || true
diff -u /gen/etc5.original/nsswitch.conf /gen/etc5/nsswitch.conf >> /gen/client.diff || true
diff -u /gen/etc5.original/openldap-ldap.conf /gen/etc5/openldap-ldap.conf >> /gen/client.diff || true
diff -u /gen/etc5.original/system-auth /gen/etc5/system-auth >> /gen/client.diff || true
diff -u /gen/etc5.original/authconfig /gen/etc5/authconfig >> /gen/client.diff || true

getent passwd username

/usr/share/openldap/migration/migrate_passwd.pl /etc/passwd || true
