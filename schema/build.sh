#!/bin/bash
# [[file:~/git/cc/cc-ldap-centos/docs/index.org::#minimal-schema][build-schema]]

cd /schema

ldapmodify -v -D cn=Manager,cn=config -f domain.ldif -x -w $LDAP_ROOT_PASSWORD
ldapadd -x -D 'cn=Manager,dc=mercury,dc=febras,dc=net' -w $LDAP_MANAGER_PASSWORD -f base.ldif
ldapadd -x -D 'cn=Manager,dc=mercury,dc=febras,dc=net' -w $LDAP_MANAGER_PASSWORD -f user.ldif
ldapsearch -x -LLL -D 'cn=Manager,cn=config' -b 'dc=mercury,dc=febras,dc=net' '*' -w $LDAP_ROOT_PASSWORD
# build-schema ends here
# Подготовка\ к\ тестированию\ аутентификации\ при\ помощи\ LDAP:1 ends here