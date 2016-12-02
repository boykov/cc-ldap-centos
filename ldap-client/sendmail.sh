#!/bin/bash

echo test | sendmail -v username@localhost
echo forwarding test: it works!  | sendmail -v username@mercury.febras.net
sleep 1
cat /var/mail/username > /gen/sendmail
