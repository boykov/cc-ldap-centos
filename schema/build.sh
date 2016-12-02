#!/bin/bash
# [[file:~/git/cc/cc-ldap-centos/docs/index.org::#minimal-schema][build-schema]]

cd /schema

cp domain.ldif domain+.ldif
MANAGER_PWD=$(slappasswd -s $LDAP_MANAGER_PASSWORD)
# Use bash variable substitution to escape special chars http://stackoverflow.com/a/14339705
sed -i "s+%LDAP_MANAGER_PASSWORD%+${MANAGER_PWD//+/\\+}+" domain+.ldif
ldapmodify -v -D cn=Manager,cn=config -f domain+.ldif -x -w $LDAP_ROOT_PASSWORD
rm domain+.ldif
ldapadd -x -D 'cn=Manager,dc=mercury,dc=febras,dc=net' -w $LDAP_MANAGER_PASSWORD -f base.ldif
ldapadd -x -D 'cn=Manager,dc=mercury,dc=febras,dc=net' -w $LDAP_MANAGER_PASSWORD -f sudoers.ldif
# build-schema ends here
# [[file:~/git/cc/cc-ldap-centos/docs/index.org::#new-user-ldap][add-user]]
ldapadd -x -D 'cn=Manager,dc=mercury,dc=febras,dc=net' -w $LDAP_MANAGER_PASSWORD -f user.ldif

# add-user ends here
# build\.sh:1 ends here
