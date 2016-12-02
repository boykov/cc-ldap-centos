#!/bin/bash
# [[file:~/git/cc/cc-ldap-centos/docs/index.org::#install-openldap][run-prefix]]

set -e

if [ ! -f /data/lib/ldap/DB_CONFIG ]; then
    if [ -z "$LDAP_ROOT_PASSWORD" -o -z "$LDAP_MANAGER_PASSWORD" ]; then
	echo "Need LDAP_ROOT_PASSWORD and LDAP_MANAGER_PASSWORD"
	exit
    fi

# run-prefix ends here
# [[file:~/git/cc/cc-ldap-centos/docs/index.org::#configure-hdb][run-db-config6]]
    cp /usr/share/openldap-servers/DB_CONFIG.example /var/lib/ldap/DB_CONFIG
    chown ldap. /var/lib/ldap/DB_CONFIG

# run-db-config6 ends here
# [[file:~/git/cc/cc-ldap-centos/docs/index.org::#add-schemas][schema-prepare6]]
    cp /usr/share/doc/sudo-1.8.6p3/schema.OpenLDAP /etc/openldap/schema/sudo.schema
    chown ldap. /etc/openldap/schema/sudo.schema

# schema-prepare6 ends here
# [[file:~/git/cc/cc-ldap-centos/docs/index.org::#configure-slapd][run-slapd-conf6]]
    cp /root/slapd.conf.obsolete /etc/openldap/slapd.conf
    ROOT_PWD=$(slappasswd -s $LDAP_ROOT_PASSWORD)
    # Use bash variable substitution to escape special chars http://stackoverflow.com/a/14339705
    sed -i "s+%LDAP_ROOT_PASSWORD%+${ROOT_PWD//+/\\+}+" /etc/openldap/slapd.conf
    chown ldap. /etc/openldap/slapd.conf
    rm -rf /etc/openldap/slapd.d

    diff /usr/share/openldap-servers/slapd.conf.obsolete /etc/openldap/slapd.conf > /gen/slapd.obsolete.diff || true
# run-slapd-conf6 ends here
# [[file:~/git/cc/cc-ldap-centos/docs/index.org::#configure-slapd][run-slapd-start6]]
    service slapd start
# run-slapd-start6 ends here
# [[file:~/git/cc/cc-ldap-centos/docs/index.org::#configure-slapd][run-slapd-d]]
    sleep 3

    kill -INT `cat /var/run/openldap/slapd.pid`
    rm -rf /etc/openldap/slapd.d
    oldpath=`pwd`
    cd /etc/openldap
    mkdir slapd.d
    slaptest -f slapd.conf -F slapd.d
    chown -R ldap:ldap slapd.d
    chmod -R 0750 slapd.d
    mv slapd.conf slapd.conf.bak
    cd $oldpath
# run-slapd-d ends here
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
    sed -i "s+%LDAP_ROOT_PASSWORD%+${ROOT_PWD//+/\\+}+" /root/slapd.ldif
    slapadd -b cn=config -F /etc/openldap/slapd.d -l /root/slapd.ldif || true
    chown -R ldap. /etc/openldap/slapd.d/

# schema2ldif ends here
# [[file:~/git/cc/cc-ldap-centos/docs/index.org::#configure-slapd][run-slapd-start6]]
    service slapd start
# run-slapd-start6 ends here
# [[file:~/git/cc/cc-ldap-centos/docs/index.org::#configure-slapd][run-postfix]]
    kill -INT `cat /var/run/openldap/slapd.pid` || true
    sleep 2

    mkdir /data/lib /data/etc
    cp -ar /var/lib/ldap /data/lib
    cp -ar /etc/openldap /data/etc
fi

rm -rf /var/lib/ldap && ln -s /data/lib/ldap /var/lib/ldap
rm -rf /etc/openldap && ln -s /data/etc/openldap /etc/openldap

exec /usr/sbin/slapd -h "ldap:/// ldaps:/// ldapi:///" -u ldap -d $DEBUG_LEVEL
# run-postfix ends here
# Дополнительно\.\ Предварительная\ настройка\ схемы\ каталога\ LDAP\ с\ помощью\ ldif\ формата:1 ends here
