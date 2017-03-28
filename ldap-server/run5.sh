#!/bin/bash
# [[file:~/git/cc/cc-ldap-centos/docs/index.org::#install-openldap][run-prefix]]

set -e

if [ ! -f /data/lib/ldap/DB_CONFIG ]; then
    if [ -z "$LDAP_ROOT_PASSWORD" -o -z "$LDAP_MANAGER_PASSWORD" ]; then
	echo "Need LDAP_ROOT_PASSWORD and LDAP_MANAGER_PASSWORD"
	exit
    fi

    sed -i "s|$servers->setValue('login','attr','uid');|// $servers->setValue('login','attr','uid');|g" /etc/phpldapadmin/config.php
    sed -i "s|  Allow from 127.0.0.1|  Allow from 127.0.0.1 172.17.0.1|g" /etc/httpd/conf.d/phpldapadmin.conf
# run-prefix ends here
# [[file:~/git/cc/cc-ldap-centos/docs/index.org::#configure-hdb][run-db-config5]]
    cp /etc/openldap/DB_CONFIG.example /var/lib/ldap/DB_CONFIG
    chown ldap. /var/lib/ldap/DB_CONFIG

# run-db-config5 ends here
# [[file:~/git/cc/cc-ldap-centos/docs/index.org::#add-schemas][schema-prepare5]]
    cp /usr/share/doc/sudo-1.7.2p1/schema.OpenLDAP /etc/openldap/schema/sudo.schema
    chown ldap. /etc/openldap/schema/sudo.schema

# schema-prepare5 ends here
# [[file:~/git/cc/cc-ldap-centos/docs/index.org::#configure-slapd][run-slapd-conf5]]
    mkdir -p /etc/openldap/certs/
    cp /root/server.key /root/server.crt /root/ca-bundle.crt /etc/openldap/certs/
    chown ldap. /etc/openldap/certs/server.key /etc/openldap/certs/server.crt /etc/openldap/certs/ca-bundle.crt

    mv /etc/openldap/slapd.conf /etc/openldap/slapd.conf.original
    cp /root/slapd.conf /etc/openldap/slapd.conf
    ROOT_PWD=$(slappasswd -s $LDAP_ROOT_PASSWORD)
    # Use bash variable substitution to escape special chars http://stackoverflow.com/a/14339705
    sed -i "s+%LDAP_ROOT_PASSWORD%+${ROOT_PWD//+/\\+}+" /etc/openldap/slapd.conf
    chown ldap. /etc/openldap/slapd.conf

    diff /etc/openldap/slapd.conf.original /etc/openldap/slapd.conf > /gen/slapd.diff || true
# run-slapd-conf5 ends here
# [[file:~/git/cc/cc-ldap-centos/docs/index.org::#configure-slapd][run-slapd-start5]]
    service ldap start
# run-slapd-start5 ends here
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
# [[file:~/git/cc/cc-ldap-centos/docs/index.org::#configure-slapd][run-postfix]]
    kill -INT `cat /var/run/openldap/slapd.pid` || true
    sleep 2

    mkdir /data/lib /data/etc
    cp -ar /var/lib/ldap /data/lib
    cp -ar /etc/openldap /data/etc
fi

rm -rf /var/lib/ldap && ln -s /data/lib/ldap /var/lib/ldap
rm -rf /etc/openldap && ln -s /data/etc/openldap /etc/openldap

service httpd start
exec /usr/sbin/slapd -h "ldap:/// ldaps:/// ldapi:///" -u ldap -d $DEBUG_LEVEL
# run-postfix ends here
# Дополнительно\.\ Предварительная\ настройка\ схемы\ каталога\ LDAP\ с\ помощью\ ldif\ формата:1 ends here
