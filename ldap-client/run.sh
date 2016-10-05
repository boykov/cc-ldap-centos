#!/bin/bash

# for testing purpose
LDAP_SERVER="172.17.0.3"
LDAP_BASEDN="dc=tuleap,dc=local"

authconfig --enablemkhomedir --enableldap --enableldapauth --ldapserver=$LDAP_SERVER --ldapbasedn=$LDAP_BASEDN --update

getent passwd username
