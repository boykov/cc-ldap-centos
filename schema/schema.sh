#!/bin/bash
# [[file:~/git/cc/cc-ldap-centos/docs/index.org::#schema.sh][schemash-prefix]]

function password() {
    ldappasswd -h $1 -x -D "uid=username,ou=users,dc=mercury,dc=febras,dc=net" -w p@ssw0rd -s new_p@ssw0rd
    ldappasswd -h $1 -x -D "uid=username,ou=users,dc=mercury,dc=febras,dc=net" -w new_p@ssw0rd -s p@ssw0rd
}

function password_out() {
cat <<EOF
EOF
}

# schemash-prefix ends here
# [[file:~/git/cc/cc-ldap-centos/docs/index.org::#schema.sh][modify-sh]]
function modify() {
    ldapmodify -h $1 -x -D "cn=Manager,dc=mercury,dc=febras,dc=net" -w manager <<EOF
dn: uid=username,ou=users,dc=mercury,dc=febras,dc=net
changetype: modify
replace: loginShell
loginShell: /bin/sh
-
EOF
    ldapsearch -x -h $1 -LLL -D 'cn=Manager,dc=mercury,dc=febras,dc=net' -b 'uid=username,ou=users,dc=mercury,dc=febras,dc=net' '(loginShell=*)' -w manager | grep loginShell
}

function modify_out() {
cat <<EOF
modifying entry "uid=username,ou=users,dc=mercury,dc=febras,dc=net"

loginShell: /bin/sh
EOF
}
# modify-sh ends here
# [[file:~/git/cc/cc-ldap-centos/docs/index.org::#schema.sh][schemash-postfix]]

function ssh() {
    sshpass -p p@ssw0rd ssh -o "GSSAPIAuthentication no" -o "UserKnownHostsFile /dev/null" -o StrictHostKeyChecking=no -o "VerifyHostKeyDNS no" -t username@$2 sudo ls /root/Dockerfile5 2> /dev/null || true
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
dn: uid=username,ou=users,dc=mercury,dc=febras,dc=net
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

dn: uid=sendmail,ou=public,dc=mercury,dc=febras,dc=net
uid: sendmail
objectClass: inetLocalMailRecipient
objectClass: account
mailLocalAddress: username@mercury.febras.net
mailRoutingAddress: username@localhost

EOF
}

function denied() {
    docker exec $3 slapacl -b 'uid=username,ou=users,dc=mercury,dc=febras,dc=net' "gecos/read" 2>&1
}

function denied_out() {
cat <<EOF
read access to gecos: DENIED
EOF
}

function getent() {
    sshpass -p p@ssw0rd ssh -o "GSSAPIAuthentication no" -o "UserKnownHostsFile /dev/null" -o StrictHostKeyChecking=no -o "VerifyHostKeyDNS no" -t username@$2 sudo getent passwd username 2> /dev/null || true
}

function getent_out() {
cat <<EOF
username:x:1050:1050:User Name:/home/webminder:/bin/sh
EOF
}

function homedir() {
    sshpass -p p@ssw0rd ssh -o "GSSAPIAuthentication no" -o "UserKnownHostsFile /dev/null" -o StrictHostKeyChecking=no -o "VerifyHostKeyDNS no" -t username@$2 ls /home 2> /dev/null || true
}

function homedir_out() {
cat <<EOF
webminder
EOF
}
# schemash-postfix ends here
# schema\.sh:1 ends here
