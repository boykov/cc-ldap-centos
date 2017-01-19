#!/bin/bash
# [[file:~/git/cc/cc-ldap-centos/docs/index.org::#client-packages][client7-run-prefix]]

cp -R /etc /gen/etc7/etc

opts="-N -x fingerprint-auth-ac \
         -x fingerprint-auth \
         -x password-auth-ac \
         -x password-auth \
         -x smartcard-auth-ac \
         -x smartcard-auth \
         -x system-auth-ac \
         -x S12nslcd \
         -x K88nslcd \
         -x authconfig \
         "

# client7-run-prefix ends here
# [[file:~/git/cc/cc-ldap-centos/docs/index.org::#client-packages][client-libuser]]
sed -i "s|^modules = files shadow|modules = files shadow ldap|" /etc/libuser.conf
sed -i "s|create_modules = files shadow|create_modules = ldap files shadow|" /etc/libuser.conf
sed -i "s|# server = ldap|server = ldap://$LDAP_SERVER|" /etc/libuser.conf
sed -i "s|# basedn = dc=example,dc=com|basedn = $LDAP_BASEDN|" /etc/libuser.conf
sed -i "s|# userBranch = ou=People|userBranch = ou=users|" /etc/libuser.conf
sed -i "s|# groupBranch = ou=Group|groupBranch = ou=groups|" /etc/libuser.conf
sed -i "s|# binddn = cn=Manager,dc=example,dc=com|binddn = cn=Manager,dc=mercury,dc=febras,dc=net|" /etc/libuser.conf
# client-libuser ends here
# [[file:~/git/cc/cc-ldap-centos/docs/index.org::#client-packages][client7-run-setup]]
authconfig --enablemkhomedir --enableldap --enableldapauth \
	   --ldapserver=$LDAP_SERVER --ldapbasedn=$LDAP_BASEDN --update
# client7-run-setup ends here
# [[file:~/git/cc/cc-ldap-centos/docs/index.org::#client-packages][client7-run-sudoers]]

echo sudoers:  files ldap >> /etc/nsswitch.conf

echo uri ldap://$LDAP_SERVER/ >> /etc/sudo-ldap.conf
echo base dc=mercury,dc=febras,dc=net >> /etc/sudo-ldap.conf
echo sudoers_base dc=mercury,dc=febras,dc=net >> /etc/sudo-ldap.conf
echo sudoers_debug 0 >> /etc/sudo-ldap.conf
echo binddn uid=authenticator,ou=system,dc=mercury,dc=febras,dc=net >> /etc/sudo-ldap.conf
echo bindpw secret >> /etc/sudo-ldap.conf

# echo binddn uid=authenticator,ou=system,dc=mercury,dc=febras,dc=net >> /etc/pam_ldap.conf
# echo bindpw secret >> /etc/pam_ldap.conf

echo ldap_version 3 >> /etc/nslcd.conf
# echo filter passwd \(uid=*\) >>  /etc/nslcd.conf
echo binddn uid=authenticator,ou=system,dc=mercury,dc=febras,dc=net >> /etc/nslcd.conf
echo bindpw secret >> /etc/nslcd.conf

chmod 600 /etc/sudo-ldap.conf
# chmod 600 /etc/pam_ldap.conf
chmod 600 /etc/nslcd.conf

# /etc/init.d/nslcd stop
# rm /var/run/nslcd/*
# /etc/init.d/nslcd start

sed -i "s|	positive-time-to-live	passwd		600|	positive-time-to-live	passwd		0|g" /etc/nscd.conf
sed -i "s|	negative-time-to-live	passwd		20|	negative-time-to-live	passwd		0|g" /etc/nscd.conf

/usr/sbin/nscd &
/usr/sbin/nslcd -d &

# client7-run-sudoers ends here
# [[file:~/git/cc/cc-ldap-centos/docs/index.org::#client-packages][client7-run-postfix]]

cp -R /etc /gen/etc7/etcnew

diff -r $opts /gen/etc7/etc /gen/etc7/etcnew > /gen/client7.diff || true
sed -i 's|.*etcnew|/etc|g' /gen/client7.diff
diff -q -r /gen/etc7/etc /gen/etc7/etcnew | grep -v "K88nslcd" | grep -v "S12nslcd" | awk -F"etcnew" '{print "/etc"$2}' | sed 's/ differ//g' | sed 's|: |/|g' > /gen/client7-files.diff || true

rm -rf /gen/etc7/etc
rm -rf /gen/etc7/etcnew

getent passwd username

# do not need migrate centos 7 users
# /usr/share/migrationtools/migrate_passwd.pl /etc/passwd > /gen/passwd7.ldif
# /usr/share/migrationtools/migrate_group.pl /etc/group > /gen/group7.ldif
/usr/sbin/sshd -D
# client7-run-postfix ends here
# Требуемые\ пакеты:1 ends here
