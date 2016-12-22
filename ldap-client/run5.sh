#!/bin/bash
# [[file:~/git/cc/cc-ldap-centos/docs/index.org::#client-packages][client5-run-prefix]]

cp -R /etc /gen/etc5/etc

opts="-N -x group \
         -x group- \
         -x shadow \
         -x gshadow \
         -x system-auth-ac \
         -x authconfig \
         -x passwd- \
         -x passwd"

# client5-run-prefix ends here
# [[file:~/git/cc/cc-ldap-centos/docs/index.org::#client-packages][client5-run-setup]]
authconfig --enableshadow --enablemkhomedir --enableldap --enableldapauth \
	   --ldapserver=$LDAP_SERVER --ldapbasedn=$LDAP_BASEDN --update

sed -i "s|pam_mkhomedir.so|pam_mkhomedir.so skel=/etc/skel umask=0077|g" /etc/pam.d/system-auth
# client5-run-setup ends here
# [[file:~/git/cc/cc-ldap-centos/docs/index.org::#client-packages][client5-run-sudoers]]

echo sudoers_base dc=mercury,dc=febras,dc=net >> /etc/ldap.conf
echo sudoers_debug 0 >> /etc/ldap.conf
echo binddn uid=authenticator,ou=system,dc=mercury,dc=febras,dc=net >> /etc/ldap.conf
echo bindpw secret >> /etc/ldap.conf

chmod 600 /etc/ldap.conf

# client5-run-sudoers ends here
# [[file:~/git/cc/cc-ldap-centos/docs/index.org::#client-packages][client5-run-postfix]]

cp -R /etc /gen/etc5/etcnew

diff -r $opts /gen/etc5/etc /gen/etc5/etcnew > /gen/client5.diff || true
sed -i 's|.*etcnew|/etc|g' /gen/client5.diff
diff -q -r /gen/etc5/etc /gen/etc5/etcnew | awk -F"etcnew" '{print "/etc"$2}' | sed 's/ differ//g' | sed 's|: |/|g' > /gen/client5-files.diff || true

rm -rf /gen/etc5/etc
rm -rf /gen/etc5/etcnew

getent passwd username

/usr/share/openldap/migration/migrate_passwd.pl /etc/passwd > /gen/passwd.ldif

/usr/share/openldap/migration/migrate_group.pl /etc/group > /gen/group.ldif

/usr/sbin/sshd -D
# client5-run-postfix ends here
# Требуемые\ пакеты:1 ends here
