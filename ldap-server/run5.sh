#!/bin/bash
# [[file:~/git/cc/cc-ldap-centos/docs/index.org::#install-openldap][run-prefix]]

set -e

if [ ! -f /data/lib/ldap/DB_CONFIG ]; then
    if [ -z "$LDAP_ROOT_PASSWORD" -o -z "$LDAP_MANAGER_PASSWORD" ]; then
	echo "Need LDAP_ROOT_PASSWORD and LDAP_MANAGER_PASSWORD"
	exit
    fi

# run-prefix ends here
# [[file:~/git/cc/cc-ldap-centos/docs/index.org::#configure-hdb][run-db-config5]]
    cp /etc/openldap/DB_CONFIG.example /var/lib/ldap/DB_CONFIG
    chown ldap. /var/lib/ldap/DB_CONFIG

# run-db-config5 ends here
# [[file:~/git/cc/cc-ldap-centos/docs/index.org::#configure-slapd][run-slapd-conf5]]
    cp /usr/share/doc/sudo-1.7.2p1/schema.OpenLDAP /etc/openldap/schema/sudo.schema
    chown ldap. /etc/openldap/schema/sudo.schema

# run-slapd-conf5 ends here
# [[file:~/git/cc/cc-ldap-centos/docs/index.org::#configure-slapd][schema2ldif]]
    rm -rf /etc/openldap/slapd.d
    rm -f /etc/openldap/slapd.conf
    mkdir -p /etc/openldap/slapd.d

    oldpath=`pwd`
    cd /etc/openldap/schema
    SCHEMAD=`pwd` SCHEMAS='core.schema cosine.schema inetorgperson.schema nis.schema sudo.schema' /root/2.5-schema-ldif.sh
    cp -R /etc/openldap/schema /gen/schema
    cd $oldpath

    ROOT_PWD=$(slappasswd -s $LDAP_ROOT_PASSWORD)
    # Use bash variable substitution to escape special chars http://stackoverflow.com/a/14339705
    sed -i "s+%LDAP_ROOT_PASSWORD%+${ROOT_PWD//+/\\+}+" /root/startup-config.ldif
    slapadd -b cn=config -F /etc/openldap/slapd.d -l /root/startup-config.ldif || true
    chown -R ldap. /etc/openldap/slapd.d/

# schema2ldif ends here
# [[file:~/git/cc/cc-ldap-centos/docs/index.org::#configure-slapd][run-slapd-start5]]
    service ldap start
# run-slapd-start5 ends here
# [[file:~/git/cc/cc-ldap-centos/docs/index.org::#configure-slapd][run-modify]]
    sleep 2

    ldapadd -v -D cn=Manager,cn=config -f /root/slapd.ldif -x -w $LDAP_ROOT_PASSWORD || true
# run-modify ends here
# [[file:~/git/cc/cc-ldap-centos/docs/index.org::#configure-slapd][add-front5]]
    ldapadd -v -D cn=Manager,cn=config -f /root/front.ldif -x -w $LDAP_ROOT_PASSWORD || true
# add-front5 ends here
# [[file:~/git/cc/cc-ldap-centos/docs/index.org::#configure-slapd][run-postfix]]
    kill -INT `cat /var/run/openldap/slapd.pid`
    sleep 2

    mkdir /data/lib /data/etc
    cp -ar /var/lib/ldap /data/lib
    cp -ar /etc/openldap /data/etc
fi

rm -rf /var/lib/ldap && ln -s /data/lib/ldap /var/lib/ldap
rm -rf /etc/openldap && ln -s /data/etc/openldap /etc/openldap

exec /usr/sbin/slapd -h "ldap:/// ldaps:/// ldapi:///" -u ldap -d $DEBUG_LEVEL
# run-postfix ends here
# Предварительная\ настройка\ схемы\ БД\ LDAP:1 ends here
