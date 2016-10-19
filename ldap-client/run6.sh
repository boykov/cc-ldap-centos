#!/bin/bash
# [[file:~/git/cc/cc-ldap-centos/docs/index.org::#client-packages][client6-run-prefix]]

cp -R /etc /gen/etc6/etc

# client6-run-prefix ends here
# [[file:~/git/cc/cc-ldap-centos/docs/index.org::#client-packages][client6-run-setup]]
authconfig --enablemkhomedir --enableldap --enableldapauth \
	   --ldapserver=$LDAP_SERVER --ldapbasedn=$LDAP_BASEDN --update

opts="-N -x fingerprint-auth-ac -x password-auth-ac \
-x smartcard-auth-ac -x system-auth-ac -x S12nslcd -x K88nslcd"
# client6-run-setup ends here
# [[file:~/git/cc/cc-ldap-centos/docs/index.org::#client-packages][client6-run-sudoers]]

echo sudoers:  files ldap >> /etc/nsswitch.conf

echo uri ldap://$LDAP_SERVER/ >> /etc/sudo-ldap.conf
echo base dc=mercury,dc=febras,dc=net >> /etc/sudo-ldap.conf
echo sudoers_base dc=mercury,dc=febras,dc=net >> /etc/sudo-ldap.conf
echo sudoers_debug 0 >> /etc/sudo-ldap.conf

# client6-run-sudoers ends here
# [[file:~/git/cc/cc-ldap-centos/docs/index.org::#client-packages][client6-run-postfix]]

cp -R /etc /gen/etc6/etcnew

diff -r $opts /gen/etc6/etc /gen/etc6/etcnew > /gen/client6.diff || true
sed -i 's|.*etcnew|/etc|g' /gen/client6.diff
diff -q -r /gen/etc6/etc /gen/etc6/etcnew | grep -v "K88nslcd" | grep -v "S12nslcd" | awk -F"etcnew" '{print "/etc"$2}' | sed 's/ differ//g' | sed 's|: |/|g' > /gen/client6-files.diff || true

rm -rf /gen/etc6/etc
rm -rf /gen/etc6/etcnew

getent passwd username

# do not need migrate centos 6 users
# /usr/share/migrationtools/migrate_passwd.pl /etc/passwd > /gen/passwd6.ldif
# /usr/share/migrationtools/migrate_group.pl /etc/group > /gen/group6.ldif
/usr/sbin/sshd -D
# client6-run-postfix ends here
# Используемые\ пакеты:1 ends here
