gen = /home/eab/git/cc/cc-ldap-centos/gen/
schema = /home/eab/git/cc/cc-ldap-centos/schema/
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
	docker run --name cc-ldap-centos$(1) -v $(schema):/schema -v $(gen):/gen --volumes-from cc-ldap-data$(1) -e LDAP_ROOT_PASSWORD=$(LDAP_ROOT_PASSWORD) -e LDAP_MANAGER_PASSWORD=$(LDAP_MANAGER_PASSWORD) cc-ldap-dev$(1) &
	sleep 1
endef

define fix_run
	sed -i '2d' $(1)
	chmod 0755 $(1)
endef

tangle: docs/index.org
	mkdir -p gen
	@emacsclient -s serverN --eval "(progn (find-file \"docs/index.org\") (org-odt-export-to-odt) (org-publish-current-file t) (eab/tangle-init))" > /dev/null
	mv docs/index.odt gen/
	$(call fix_run,ldap-server/run6.sh)
	$(call fix_run,ldap-server/run5.sh)
	$(call fix_run,ldap-client/run6.sh)
	$(call fix_run,ldap-client/run5.sh)
	$(call fix_run,schema/build.sh)

build-server:
	cd ldap-server && docker build -f ./Dockerfile$(n) -t cc-ldap-dev$(n) .
	docker run --name cc-ldap-data$(n) -v /data busybox true || true
	docker run --name cc-ldap-centos$(n) -v $(schema):/schema -v $(gen):/gen --volumes-from cc-ldap-data$(n) -e LDAP_ROOT_PASSWORD=$(LDAP_ROOT_PASSWORD) -e LDAP_MANAGER_PASSWORD=$(LDAP_MANAGER_PASSWORD) cc-ldap-dev$(n) &
	sleep 15
	$(call create_backup,$(n))

build-client:
	$(eval ip = $(call get_ip,$(server)))
	cd ldap-client && docker build -f ./Dockerfile$(n) -t cc-ldap-cli$(n) .
	docker run -d --name cc-ldap-client$(n) -v $(gen):/gen -e LDAP_SERVER=$(ip) -e LDAP_BASEDN=$(LDAP_BASEDN) cc-ldap-cli$(n)

start:
	docker ps -a | grep cc-ldap-centos$(n) > /dev/null || make build-server n=$(n)
	docker start cc-ldap-centos$(n)
	sleep 1
	make build-client n=$(n) server=cc-ldap-centos$(k)
	make build-schema server=cc-ldap-centos$(n)
	sleep 1
	make test-client server=cc-ldap-client$(n)

build-schema:
	$(eval ip = $(call get_ip,$(server)))
	docker exec $(server) /schema/build.sh

test-client:
	$(eval ip = $(call get_ip,$(server)))
	sshpass -p p@ssw0rd ssh -o "GSSAPIAuthentication no" -o "UserKnownHostsFile /dev/null" -o StrictHostKeyChecking=no -o "VerifyHostKeyDNS no" -t username@$(ip) sudo ls /root

test:
	make start n=6 k=6
	make start n=5 k=6
	make clear

clear:
	$(call recreate_cc-ldap,6)
	$(call recreate_cc-ldap,5)

	docker rm -f cc-ldap-client6
	docker rm -f cc-ldap-client5

full-clear:
	docker rm -f -v cc-ldap-centos6 || true
	docker rm -f -v cc-ldap-centos5 || true

	docker rm cc-ldap-data6 || true
	docker rm cc-ldap-data5 || true

