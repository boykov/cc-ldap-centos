gen = /home/eab/git/cc/cc-ldap-centos/gen/
LDAP_SERVER = "172.17.0.6"
LDAP_BASEDN = "dc=mercury,dc=febras,dc=net"

tangle: docs/index.org
	mkdir -p gen
	@emacsclient -s serverN --eval "(progn (find-file \"docs/index.org\") (org-publish-current-file) (eab/tangle-init))" > /dev/null
	sed -i '2d' ldap-server/run.sh
	sed -i '2d' ldap-server/run6.sh
	sed -i '2d' ldap-client/run.sh
	sed -i '2d' ldap-client/run6.sh
	chmod 0755 ldap-server/run.sh
	chmod 0755 ldap-server/run6.sh
	chmod 0755 ldap-client/run.sh
	chmod 0755 ldap-client/run6.sh

build-server5:
	cd ldap-server && docker build -t cc-ldap-dev5 .
	docker run --name cc-ldap-data5 -v /data busybox true || true
	docker run --name cc-ldap-centos5 -v $(gen):/gen --volumes-from cc-ldap-data5 cc-ldap-dev5 &
	sleep 15

build-server6:
	cd ldap-server && docker build -f ./Dockerfile-centos6 -t cc-ldap-dev6 .
	docker run --name cc-ldap-data6 -v /data busybox true || true
	docker run --name cc-ldap-centos6 -v $(gen):/gen --volumes-from cc-ldap-data6 cc-ldap-dev6 &
	sleep 15

build-client5:
	cd ldap-client && docker build -t cc-ldap-cli5 .
	docker run --rm -v $(gen):/gen -e LDAP_SERVER=$(LDAP_SERVER) -e LDAP_BASEDN=$(LDAP_BASEDN) cc-ldap-cli5

build-client6:
	cd ldap-client && docker build -f ./Dockerfile-centos6 -t cc-ldap-cli6 .
	docker run --rm -v $(gen):/gen -e LDAP_SERVER=$(LDAP_SERVER) -e LDAP_BASEDN=$(LDAP_BASEDN) cc-ldap-cli6

start:
	docker ps -a | grep cc-ldap-centos5 > /dev/null || make build-server5
	docker start cc-ldap-centos5
	docker ps -a | grep cc-ldap-centos6 > /dev/null || make build-server6
	docker start cc-ldap-centos6
	sleep 1

build-schema:
	$(eval host = $(shell docker inspect -f {{.NetworkSettings.IPAddress}} $(server)))
	echo $(host)
	ldapsearch -x -h $(host) -LLL -D 'cn=Manager,cn=config' -b 'dc=mercury,dc=febras,dc=net' '*' -w root

test: start
	make build-schema server=cc-ldap-centos5
	make build-schema server=cc-ldap-centos6
	make build-client5
	make build-client6

clear:
	docker rm -f -v cc-ldap-centos5
	docker rm cc-ldap-data5
	docker rm -f -v cc-ldap-centos6
	docker rm cc-ldap-data6
