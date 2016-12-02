#!/bin/bash

echo test | sendmail -v username@localhost
echo test2 | sendmail -v username@mercury.febras.net
sleep 1
cat /var/mail/username > /gen/sendmail
