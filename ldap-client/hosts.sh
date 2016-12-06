#!/bin/bash

rm -f /gen/sendmail
cp /etc/mail/sendmail.mc /etc/mail/sendmail.mc.bak

# fix sendmail timeout
ip_name=$(tail -n 1 /etc/hosts)
name=$(echo $ip_name | awk '{print $2}')
cat /etc/hosts | sed '$d' > /etc/hosts
echo "127.0.0.1 $name.localdomain $name" >> /etc/hosts

echo pwcheck_method:pam > /etc/sasl2/Sendmail.conf

echo $2 > /etc/mail/ldap-secret

cp -f /root/sendmail$1.mc /etc/mail/sendmail.mc
diff /etc/mail/sendmail.mc /etc/mail/sendmail.mc.bak > /gen/sendmail.diff
m4 /etc/mail/sendmail.mc > /etc/mail/sendmail.cf
/etc/init.d/sendmail start
sleep 1

echo test | sendmail -v username@localhost
echo forwarding test: it works!  | sendmail -v username@mercury.febras.net
sleep 1
cat /var/mail/username > /gen/sendmail
