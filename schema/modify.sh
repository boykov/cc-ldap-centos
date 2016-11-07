#!/bin/bash

ldapmodify -h $1 -x -D "uid=username,ou=people,dc=mercury,dc=febras,dc=net" -w 1 <<EOF
dn: uid=username,ou=people,dc=mercury,dc=febras,dc=net
changetype: modify
replace: loginShell
loginShell: /bin/sh
-
EOF

