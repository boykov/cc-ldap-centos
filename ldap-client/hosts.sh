#!/bin/bash

line=$(head -n 1 /etc/hosts)
line2=$(echo $line | awk '{print $2}')
ln=$(tail -n 1 /etc/hosts)
ln2=$(echo $ln | awk '{print $2}')
     
echo "$line $line2.localdomain $ln2" >> /etc/hosts

echo pwcheck_method:pam > /etc/sasl2/Sendmail.conf

cp /root/smpwd /etc/mail/ldap-secret
cp /etc/mail/sendmail.mc /etc/mail/sendmail.mc.bak
cp -f /root/sendmail6.mc /etc/mail/sendmail.mc
m4 /root/sendmail.mc > /etc/mail/sendmail.cf
