#!/bin/bash
# [[file:~/git/cc/cc-ldap-centos/docs/index.org::#install-openldap][run-prefix]]

set -e

if [ ! -f /data/lib/ldap/DB_CONFIG ]; then
    if [ -z "$LDAP_ROOT_PASSWORD" -o -z "$LDAP_MANAGER_PASSWORD" ]; then
	echo "Need LDAP_ROOT_PASSWORD and LDAP_MANAGER_PASSWORD"
	exit
    fi

# run-prefix ends here
# [[file:~/git/cc/cc-ldap-centos/docs/index.org::#configure-bdb][run-db-config5]]
    cp /etc/openldap/DB_CONFIG.example /var/lib/ldap/DB_CONFIG
    chown ldap. /var/lib/ldap/DB_CONFIG

# run-db-config5 ends here
# [[file:~/git/cc/cc-ldap-centos/docs/index.org::#configure-slapd][run-slapd-conf5]]
    cp /usr/share/doc/sudo-1.7.2p1/schema.OpenLDAP /etc/openldap/schema/sudo.schema
    chown ldap. /etc/openldap/schema/sudo.schema

    mv /etc/openldap/slapd.conf /etc/openldap/slapd.conf.original
    cp /root/slapd.conf /etc/openldap/slapd.conf
    chown ldap. /etc/openldap/slapd.conf

    diff /etc/openldap/slapd.conf.original /etc/openldap/slapd.conf > /gen/slapd.diff || true

# run-slapd-conf5 ends here
# [[file:~/git/cc/cc-ldap-centos/docs/index.org::#configure-slapd][run-slapd-start5]]
    service ldap start
# run-slapd-start5 ends here
# [[file:~/git/cc/cc-ldap-centos/docs/index.org::#config-transform][run-slapd-d]]
    sleep 3

    kill -INT `cat /var/run/openldap/slapd.pid`
    oldpath=`pwd`
    cd /etc/openldap
    mkdir slapd.d
    slaptest -f slapd.conf -F slapd.d
    chown -R ldap:ldap slapd.d
    chmod -R 0750 slapd.d
    mv slapd.conf slapd.conf.bak
    cd $oldpath
# run-slapd-d ends here
# [[file:~/git/cc/cc-ldap-centos/docs/index.org::#configure-slapd][schema2ldif5]]
    rm -rf /etc/openldap/slapd.d
    rm -f /etc/openldap/slapd.conf
    mkdir -p /etc/openldap/slapd.d

    oldpath=`pwd`
    cd /etc/openldap/
    echo "include /etc/openldap/schema/core.schema" > cosine.schema
    cat /etc/openldap/schema/cosine.schema >> cosine.schema
    echo "include /etc/openldap/schema/core.schema" > inetorgperson.schema
    echo "include /etc/openldap/schema/cosine.schema" >> inetorgperson.schema
    cat /etc/openldap/schema/inetorgperson.schema >> inetorgperson.schema
    echo "include /etc/openldap/schema/core.schema" > nis.schema
    echo "include /etc/openldap/schema/cosine.schema" >> nis.schema
    cat /etc/openldap/schema/nis.schema >> nis.schema
    /root/schema2ldif.sh /etc/openldap/cosine.schema
    /root/schema2ldif.sh /etc/openldap/inetorgperson.schema
    /root/schema2ldif.sh /etc/openldap/nis.schema
    /root/schema2ldif.sh /etc/openldap/schema/sudo.schema
    cp cosine.ldif schema/
    cp inetorgperson.ldif schema/
    cp nis.ldif schema/
    cp sudo.ldif schema/
    cp -R schema /gen/schema
    cd $oldpath
    ls /etc/openldap/schema/

    slapadd -b cn=config -F /etc/openldap/slapd.d -l /root/startup-config.ldif || true
    chown -R ldap. /etc/openldap/slapd.d/

    service ldap start

    sleep 3

    ldapadd -v -D cn=Manager,cn=config -f /root/slapd.ldif -x -w 1 || true
# schema2ldif5 ends here
# [[file:~/git/cc/cc-ldap-centos/docs/index.org::#add-manager][run-modify]]
    sleep 3

    ROOT_PWD=$(slappasswd -s $LDAP_ROOT_PASSWORD)
    # Use bash variable subsitution to escape special chars http://stackoverflow.com/a/14339705
    sed -i "s+%LDAP_ROOT_PASSWORD%+${ROOT_PWD//+/\\+}+" /root/manager.ldif
    ldapmodify -v -D cn=Manager,cn=config -f /root/manager.ldif -x -w 1

# run-modify ends here
# [[file:~/git/cc/cc-ldap-centos/docs/index.org::#add-manager][run-postfix]]
    kill -INT `cat /var/run/openldap/slapd.pid`
    sleep 3

    mkdir /data/lib /data/etc
    cp -ar /var/lib/ldap /data/lib
    cp -ar /etc/openldap /data/etc
fi

rm -rf /var/lib/ldap && ln -s /data/lib/ldap /var/lib/ldap
rm -rf /etc/openldap && ln -s /data/etc/openldap /etc/openldap

exec /usr/sbin/slapd -h "ldap:/// ldaps:/// ldapi:///" -u ldap -d $DEBUG_LEVEL
# run-postfix ends here
# Установка\ пароля\ менеджера\ схемы:1 ends here
