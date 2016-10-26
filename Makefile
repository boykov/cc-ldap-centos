gen = /home/eab/git/cc/cc-ldap-centos/gen/
schema = /home/eab/git/cc/cc-ldap-centos/schema/
LDAP_ROOT_PASSWORD=root
LDAP_MANAGER_PASSWORD=manager
LDAP_BASEDN = "dc=mercury,dc=febras,dc=net"
name=cc-ldap

define get_ip
    $(shell docker inspect -f {{.NetworkSettings.IPAddress}} $(1))
endef

define create_backup
	docker images | grep data$(1)-backup > /dev/null || docker rm -f -v data$(1)-backup
	docker stop $(2)-centos$(1)
	docker commit $(2)-data$(1) data$(1)-backup
	docker start $(2)-centos$(1)
endef

define recreate_server
	docker rm -f -v $(2)-centos$(1)
	docker rm -f -v $(2)-data$(1)
	docker run --name $(2)-data$(1) -v /data data$(1)-backup true
	docker run --name $(2)-centos$(1) -v $(schema):/schema -v $(gen):/gen --volumes-from $(2)-data$(1) -e LDAP_ROOT_PASSWORD=$(LDAP_ROOT_PASSWORD) -e LDAP_MANAGER_PASSWORD=$(LDAP_MANAGER_PASSWORD) $(2)-dev$(1) &
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
	cd ldap-server && docker build -f ./Dockerfile$(n) -t $(name)-dev$(n) .
	docker run --name $(name)-data$(n) -v /data busybox true || true
	docker run --name $(name)-centos$(n) -v $(schema):/schema -v $(gen):/gen --volumes-from $(name)-data$(n) -e LDAP_ROOT_PASSWORD=$(LDAP_ROOT_PASSWORD) -e LDAP_MANAGER_PASSWORD=$(LDAP_MANAGER_PASSWORD) $(name)-dev$(n) &
	sleep 15
	$(call create_backup,$(n),$(name))

build-client:
	$(eval ip = $(call get_ip,$(server)))
	cd ldap-client && docker build -f ./Dockerfile$(n) -t $(name)-cli$(n) .
	docker run -d --name $(name)-client$(n) -v $(gen):/gen -e LDAP_SERVER=$(ip) -e LDAP_BASEDN=$(LDAP_BASEDN) $(name)-cli$(n)

start:
	docker ps -a | grep $(name)-centos$(n) > /dev/null || make build-server n=$(n)
	docker start $(name)-centos$(n)
	sleep 1
	make build-client n=$(n) server=$(name)-centos$(k)
	make build-schema server=$(name)-centos$(n)
	sleep 1
	make test-client server=$(name)-client$(n)
	ldapsearch -x -h $(call get_ip,$(name)-centos$(k)) -LLL -D 'cn=Manager,cn=config' -b 'dc=mercury,dc=febras,dc=net' '*' -w $(LDAP_ROOT_PASSWORD)

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
	$(call recreate_server,6,$(name))
	$(call recreate_server,5,$(name))

	docker rm -f $(name)-client6
	docker rm -f $(name)-client5

full-clear:
	docker rm -f -v $(name)-centos6 || true
	docker rm -f -v $(name)-centos5 || true

	docker rm $(name)-data6 || true
	docker rm $(name)-data5 || true

	docker rm -f $(name)-client6 || true
	docker rm -f $(name)-client5 || true
