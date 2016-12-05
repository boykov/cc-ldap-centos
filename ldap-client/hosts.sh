#!/bin/bash

rm -f /gen/sendmail

line=$(head -n 1 /etc/hosts)
ip=$(echo $line | awk '{print $1}')
line2=$(echo $line | awk '{print $2}')
ln=$(tail -n 1 /etc/hosts)
ln2=$(echo $ln | awk '{print $2}')

cp /etc/hosts /etc/hosts.tmp
sed -i '$d' /etc/hosts.tmp
cp /etc/hosts.tmp /etc/hosts

echo "$ip $ln2.localdomain $line2.localdomain $ln2 $line2" >> /etc/hosts

echo pwcheck_method:pam > /etc/sasl2/Sendmail.conf

cp /root/smpwd /etc/mail/ldap-secret
cp /etc/mail/sendmail.mc /etc/mail/sendmail.mc.bak
cp -f /root/sendmail6.mc /etc/mail/sendmail.mc
m4 /etc/mail/sendmail.mc > /etc/mail/sendmail.cf
/etc/init.d/sendmail start
sleep 1

echo test | sendmail -v username@localhost
echo forwarding test: it works!  | sendmail -v username@mercury.febras.net
sleep 1
cat /var/mail/username > /gen/sendmail
