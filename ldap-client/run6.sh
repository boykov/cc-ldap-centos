#!/bin/bash
# [[file:~/git/cc/cc-ldap-centos/docs/index.org::#client-packages][client6-run-prefix]]

cp -R /etc /gen/etc6/etc

# client6-run-prefix ends here
# [[file:~/git/cc/cc-ldap-centos/docs/index.org::#client-packages][client6-run-setup]]
authconfig --enablemkhomedir --enableldap --enableldapauth --ldapserver=$LDAP_SERVER --ldapbasedn=$LDAP_BASEDN --update
# client6-run-setup ends here
# [[file:~/git/cc/cc-ldap-centos/docs/index.org::#client-packages][client-run-sudoers]]

echo sudoers_base dc=mercury,dc=febras,dc=net >> /etc/ldap.conf
echo sudoers_debug 0 >> /etc/ldap.conf
# client-run-sudoers ends here
# [[file:~/git/cc/cc-ldap-centos/docs/index.org::#client-packages][client6-run-postfix]]

cp -R /etc /gen/etc6/etcnew

diff -u -r --unidirectional-new-file /gen/etc6/etc /gen/etc6/etcnew > /gen/client6.diff || true
diff -q -r /gen/etc6/etc /gen/etc6/etcnew > /gen/client6-files.diff || true

rm -rf /gen/etc6/etc
rm -rf /gen/etc6/etcnew

getent passwd username

# do not need migrate centos 6 users
# /usr/share/migrationtools/migrate_passwd.pl /etc/passwd > /gen/passwd6.ldif
# /usr/share/migrationtools/migrate_group.pl /etc/group > /gen/group6.ldif
# client6-run-postfix ends here
# Используемые\ пакеты:1 ends here
