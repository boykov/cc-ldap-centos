#!/bin/bash
# [[file:~/git/cc/cc-ldap-centos/docs/index.org::#schema.sh][schemash-prefix]]

function password() {
    ldappasswd -h $1 -x -D "uid=username,ou=people,dc=mercury,dc=febras,dc=net" -w p@ssw0rd -s new_p@ssw0rd
}

function password_out() {
cat <<EOF
EOF
}

function modify() {
# schemash-prefix ends here
# [[file:~/git/cc/cc-ldap-centos/docs/index.org::#schema.sh][modify-sh]]
    ldapmodify -h $1 -x -D "uid=username,ou=people,dc=mercury,dc=febras,dc=net" -w new_p@ssw0rd <<EOF
dn: uid=username,ou=people,dc=mercury,dc=febras,dc=net
changetype: modify
replace: loginShell
loginShell: /bin/sh
-
EOF
# modify-sh ends here
# [[file:~/git/cc/cc-ldap-centos/docs/index.org::#schema.sh][schemash-postfix]]
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
    sshpass -p new_p@ssw0rd ssh -o "GSSAPIAuthentication no" -o "UserKnownHostsFile /dev/null" -o StrictHostKeyChecking=no -o "VerifyHostKeyDNS no" -t username@$2 sudo ls /root/Dockerfile5 2> /dev/null || true
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
structuralObjectClass: account

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
# schemash-postfix ends here
# schema\.sh:1 ends here
