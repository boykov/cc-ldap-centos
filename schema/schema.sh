#!/bin/bash

function password() {
    ldappasswd -h $1 -x -D "uid=username,ou=people,dc=mercury,dc=febras,dc=net" -w p@ssw0rd -s 1
}

function password_out() {
cat <<EOF
EOF
}

function modify() {
    ldapmodify -h $1 -x -D "uid=username,ou=people,dc=mercury,dc=febras,dc=net" -w 1 <<EOF
dn: uid=username,ou=people,dc=mercury,dc=febras,dc=net
changetype: modify
replace: loginShell
loginShell: /bin/sh
-
EOF
}

function modify_out() {
cat <<EOF
modifying entry "uid=username,ou=people,dc=mercury,dc=febras,dc=net"

EOF
}

function login() {
    ldapsearch -x -h $1 -LLL -D 'cn=Manager,dc=mercury,dc=febras,dc=net' -b 'dc=mercury,dc=febras,dc=net' '(loginShell=*)' -w manager | grep loginShell
}

function login_out() {
cat <<EOF
loginShell: /bin/sh
EOF
}

function ssh() {
    sshpass -p 1 ssh -o "GSSAPIAuthentication no" -o "UserKnownHostsFile /dev/null" -o StrictHostKeyChecking=no -o "VerifyHostKeyDNS no" -t username@$2 sudo ls /root/Dockerfile5 2> /dev/null || true
}

function ssh_out() {
cat <<EOF
/root/Dockerfile5
EOF
}

function struct() {
    ldapsearch -x -h $1 -LLL -D 'cn=Manager,cn=config' -b 'cn=subschema' -s base + -w root | grep -o structuralObjectClass
}

function struct_out() {
cat <<EOF
structuralObjectClass
structuralObjectClass
EOF
}

function structuralObjectClass() {
    ldapsearch -x -h $1 -LLL -D 'cn=Manager,dc=mercury,dc=febras,dc=net' -b 'dc=mercury,dc=febras,dc=net' '(uid=username)' structuralObjectClass -w manager
}

function structuralObjectClass_out() {
cat <<EOF
dn: uid=username,ou=people,dc=mercury,dc=febras,dc=net
structuralObjectClass: inetOrgPerson

EOF
}

function anonymous() {
    ldapsearch -x -h $1 -LLL -x -b 'ou=public,dc=mercury,dc=febras,dc=net'
}

function anonymous_out() {
cat <<EOF
dn: ou=public,dc=mercury,dc=febras,dc=net
objectClass: organizationalUnit
ou: public

EOF
}

function nosuchobject() {
    ldapsearch -x -h $1 -LLL -x -b 'uid=username,ou=people,dc=mercury,dc=febras,dc=net' || true
}

function nosuchobject_out() {
cat <<EOF
EOF
}
