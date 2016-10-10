gen = /home/eab/git/cc/cc-ldap-centos/gen/
LDAP_SERVER = "172.17.0.6"
LDAP_BASEDN = "dc=mercury,dc=febras,dc=net"

tangle: docs/index.org
	mkdir -p gen
	diff ldap-server/slapd.conf.original ldap-server/slapd.conf > gen/slapd.diff || true
	diff ldap-server/slapd.conf.obsolete.original ldap-server/slapd.conf.obsolete > gen/slapd.obsolete.diff || true
	@emacsclient -s serverN --eval "(progn (find-file \"docs/index.org\") (org-publish-current-file) (eab/tangle-init))" > /dev/null
	chmod 0755 ldap-server/run.sh
	chmod 0755 ldap-server/run6.sh

build-server:
	cd ldap-server && docker build -t cc-ldap-dev5 .
	docker run --name cc-ldap-data5 -v /data busybox true || true
	docker run --name cc-ldap-centos5 --volumes-from cc-ldap-data5 cc-ldap-dev5 &
	sleep 15

	cd ldap-server && docker build -f ./Dockerfile-centos6 -t cc-ldap-dev6 .
	docker run --name cc-ldap-data6 -v /data busybox true || true
	docker run --name cc-ldap-centos6 --volumes-from cc-ldap-data6 cc-ldap-dev6 &
	sleep 15

build-client:
	cd ldap-client && docker build -t cc-ldap-cli5 .
	docker run --rm cc-ldap-cli5

	cd ldap-client && docker build -f ./Dockerfile-centos6 -t cc-ldap-cli6 .
	docker run --rm cc-ldap-cli6

	diff -u ldap-client/ldap.conf.original ldap-client/ldap.conf > gen/client.diff || true
	diff -u ldap-client/nsswitch.conf.original ldap-client/nsswitch.conf >> gen/client.diff || true
	diff -u ldap-client/openldap-ldap.conf.original ldap-client/openldap-ldap.conf >> gen/client.diff || true
	diff -u ldap-client/system-auth.original ldap-client/system-auth >> gen/client.diff || true
	diff -u ldap-client/authconfig.original ldap-client/authconfig >> gen/client.diff || true

start:
	docker start cc-ldap-centos5
	docker start cc-ldap-centos6
	sleep 1

build-schema:
	$(eval host = $(shell docker inspect -f {{.NetworkSettings.IPAddress}} $(server)))
	echo $(host)
	ldapsearch -x -h $(host) -LLL -D 'cn=Manager,cn=config' -b 'dc=mercury,dc=febras,dc=net' '*' -w root

test: start
	make build-schema server=cc-ldap-centos5
	make build-schema server=cc-ldap-centos6

clear:
	docker rm -f -v cc-ldap-centos5
	docker rm cc-ldap-data5
	docker rm -f -v cc-ldap-centos6
	docker rm cc-ldap-data6
