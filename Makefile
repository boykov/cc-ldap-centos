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

define fix_run
	sed -i '2d' ldap-server/run$(1).sh
	sed -i '2d' ldap-client/run$(1).sh
	chmod 0755 ldap-server/run$(1).sh
	chmod 0755 ldap-client/run$(1).sh
endef

tangle: docs/index.org
	mkdir -p gen
	@emacsclient -s serverN --eval "(progn (find-file \"docs/index.org\") (org-odt-export-to-odt) (org-publish-current-file t) (eab/tangle-init))" > /dev/null
	mv docs/index.odt gen/
	$(call fix_run,5)
	$(call fix_run,6)

build-server:
	cd ldap-server && docker build -f ./Dockerfile$(n) -t cc-ldap-dev$(n) .
	docker run --name cc-ldap-data$(n) -v /data busybox true || true
	docker run --name cc-ldap-centos$(n) -v $(gen):/gen --volumes-from cc-ldap-data$(n) -e LDAP_ROOT_PASSWORD=$(LDAP_ROOT_PASSWORD) -e LDAP_MANAGER_PASSWORD=$(LDAP_MANAGER_PASSWORD) cc-ldap-dev$(n) &
	sleep 15
	$(call create_backup,$(n))

build-client:
	$(eval ip = $(call get_ip,$(server)))
	cd ldap-client && docker build -f ./Dockerfile$(n) -t cc-ldap-cli$(n) .
	docker run -d --name cc-ldap-client$(n) -v $(gen):/gen -e LDAP_SERVER=$(ip) -e LDAP_BASEDN=$(LDAP_BASEDN) cc-ldap-cli$(n)

start:
	docker ps -a | grep cc-ldap-centos5 > /dev/null || make build-server n=5
	docker start cc-ldap-centos5
	docker ps -a | grep cc-ldap-centos6 > /dev/null || make build-server n=6
	docker start cc-ldap-centos6
	sleep 1

build-schema:
	$(eval ip = $(call get_ip,$(server)))
	ldapadd -x -h $(ip) -D 'cn=Manager,dc=mercury,dc=febras,dc=net' -w $(LDAP_MANAGER_PASSWORD) -f ldap-server/base.ldif
	ldapsearch -x -h $(ip) -LLL -D 'cn=Manager,cn=config' -b 'dc=mercury,dc=febras,dc=net' '*' -w root

test-client:
	$(eval ip = $(call get_ip,$(server)))
	sshpass -p p@ssw0rd ssh -o "UserKnownHostsFile /dev/null" -o StrictHostKeyChecking=no -o "VerifyHostKeyDNS no" -t username@$(ip) sudo ls /root

test: start
	make build-schema server=cc-ldap-centos5
	make build-schema server=cc-ldap-centos6
	make build-client n=5 server=cc-ldap-centos6
	sleep 2
	make test-client server=cc-ldap-client5
	make build-client n=6 server=cc-ldap-centos6
	sleep 2
	make test-client server=cc-ldap-client6
	$(call recreate_cc-ldap,5)
	sleep 1
	$(call recreate_cc-ldap,6)
	sleep 1
	docker rm -f cc-ldap-client5
	docker rm -f cc-ldap-client6

clear:
	docker rm -f -v cc-ldap-centos5
	docker rm cc-ldap-data5
	docker rm -f -v cc-ldap-centos6
	docker rm cc-ldap-data6
