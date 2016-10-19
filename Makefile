gen = /home/eab/git/cc/cc-ldap-centos/gen/
LDAP_ROOT_PASSWORD=root
LDAP_MANAGER_PASSWORD=manager
LDAP_BASEDN = "dc=mercury,dc=febras,dc=net"

define get_ip
    $(shell docker inspect -f {{.NetworkSettings.IPAddress}} $(1))
endef

define create_backup
	docker images | grep data$(1)-backup > /dev/null || docker rm -f -v data$(1)-backup
	docker stop cc-ldap-centos$(1)
	docker commit cc-ldap-data$(1) data$(1)-backup
	docker start cc-ldap-centos$(1)
endef

define recreate_cc-ldap
	docker rm -f -v cc-ldap-centos$(1)
	docker rm -f -v cc-ldap-data$(1)
	docker run --name cc-ldap-data$(1) -v /data data$(1)-backup true
	docker run --name cc-ldap-centos$(1) -v $(gen):/gen --volumes-from cc-ldap-data$(1) -e LDAP_ROOT_PASSWORD=$(LDAP_ROOT_PASSWORD) -e LDAP_MANAGER_PASSWORD=$(LDAP_MANAGER_PASSWORD) cc-ldap-dev$(1) &
endef

tangle: docs/index.org
	mkdir -p gen
	@emacsclient -s serverN --eval "(progn (find-file \"docs/index.org\") (org-odt-export-to-odt) (org-publish-current-file t) (eab/tangle-init))" > /dev/null
	mv docs/index.odt gen/
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
	docker run --name cc-ldap-centos5 -v $(gen):/gen --volumes-from cc-ldap-data5 -e LDAP_ROOT_PASSWORD=$(LDAP_ROOT_PASSWORD) -e LDAP_MANAGER_PASSWORD=$(LDAP_MANAGER_PASSWORD) cc-ldap-dev5 &
	sleep 15
	$(call create_backup,5)

build-server6:
	cd ldap-server && docker build -f ./Dockerfile-centos6 -t cc-ldap-dev6 .
	docker run --name cc-ldap-data6 -v /data busybox true || true
	docker run --name cc-ldap-centos6 -v $(gen):/gen --volumes-from cc-ldap-data6 -e LDAP_ROOT_PASSWORD=$(LDAP_ROOT_PASSWORD) -e LDAP_MANAGER_PASSWORD=$(LDAP_MANAGER_PASSWORD) cc-ldap-dev6 &
	sleep 15
	$(call create_backup,6)

build-client5:
	$(eval ip = $(call get_ip,$(server)))
	cd ldap-client && docker build -t cc-ldap-cli5 .
	docker run --rm --name cc-ldap-client5 -v $(gen):/gen -e LDAP_SERVER=$(ip) -e LDAP_BASEDN=$(LDAP_BASEDN) cc-ldap-cli5

build-client6:
	$(eval ip = $(call get_ip,$(server)))
	cd ldap-client && docker build -f ./Dockerfile-centos6 -t cc-ldap-cli6 .
	docker run --rm --name cc-ldap-client6 -v $(gen):/gen -e LDAP_SERVER=$(ip) -e LDAP_BASEDN=$(LDAP_BASEDN) cc-ldap-cli6

start:
	docker ps -a | grep cc-ldap-centos5 > /dev/null || make build-server5
	docker start cc-ldap-centos5
	docker ps -a | grep cc-ldap-centos6 > /dev/null || make build-server6
	docker start cc-ldap-centos6
	sleep 1

build-schema:
	$(eval ip = $(call get_ip,$(server)))
	ldapadd -x -h $(ip) -D 'cn=Manager,dc=mercury,dc=febras,dc=net' -w $(LDAP_MANAGER_PASSWORD) -f ldap-server/base.ldif
	ldapsearch -x -h $(ip) -LLL -D 'cn=Manager,cn=config' -b 'dc=mercury,dc=febras,dc=net' '*' -w root

sshpass:
	$(eval ip = $(call get_ip,$(server)))
	sshpass -p p@ssw0rd ssh -t username@$(ip) sudo ls /root
	sshpass -p p@ssw0rd ssh -t username@$(ip) sudo killall sshd || true

test: start
	make build-schema server=cc-ldap-centos5
	make build-schema server=cc-ldap-centos6
	make build-client5 server=cc-ldap-centos6 &
	sleep 2
	make sshpass server=cc-ldap-client5
	make build-client6 server=cc-ldap-centos6
	$(call recreate_cc-ldap,5)
	sleep 1
	$(call recreate_cc-ldap,6)
	sleep 1

clear:
	docker rm -f -v cc-ldap-centos5
	docker rm cc-ldap-data5
	docker rm -f -v cc-ldap-centos6
	docker rm cc-ldap-data6
