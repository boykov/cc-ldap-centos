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
	docker images | grep data$(1)-backup > /dev/null || docker rm -f -v data$(1)-backup || true
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

define fix_tangle
	sed -i '2d' $(1)
	chmod 0755 $(1)
endef

tangle: docs/index.org
	mkdir -p gen
	@emacsclient -s serverN --eval "(progn (find-file \"docs/index.org\") (org-odt-export-to-odt) (org-publish-project \"html-ldap\") (eab/tangle-init))" > /dev/null
	mv docs/index.odt gen/
	$(call fix_tangle,ldap-server/run6.sh)
	$(call fix_tangle,ldap-server/run5.sh)
	$(call fix_tangle,ldap-client/run6.sh)
	$(call fix_tangle,ldap-client/run5.sh)
	$(call fix_tangle,schema/build.sh)

build-server:
	docker build -f ldap-server/Dockerfile$(n) -t $(name)-dev$(n) .
	docker run --name $(name)-data$(n) -v /data busybox true || true
	docker run --name $(name)-centos$(n) -v $(schema):/schema -v $(gen):/gen --volumes-from $(name)-data$(n) -e LDAP_ROOT_PASSWORD=$(LDAP_ROOT_PASSWORD) -e LDAP_MANAGER_PASSWORD=$(LDAP_MANAGER_PASSWORD) $(name)-dev$(n) &
	sleep 7
	$(call create_backup,$(n),$(name))

build-client:
	$(eval ip = $(call get_ip,$(server)))
	docker build -f ldap-client/Dockerfile$(n) -t $(name)-cli$(n) .
	docker run -d --name $(name)-client$(n) -v $(gen):/gen -e LDAP_SERVER=$(ip) -e LDAP_BASEDN=$(LDAP_BASEDN) $(name)-cli$(n)

start:
	echo entered to start $(n) $(k) >> gen/test.log
	docker ps -a | grep $(name)-centos$(n) > /dev/null || make build-server n=$(n)
	docker start $(name)-centos$(n)
	echo server$(k) built >> gen/test.log
	sleep 1
	make build-client n=$(n) server=$(name)-centos$(k)
	echo client$(n) built >> gen/test.log
	make build-schema server=$(name)-centos$(n)
	echo schema created >> gen/test.log
	sleep 1
	make test-client server=$(name)-client$(n) k=$(k) >> gen/test.log
	make test-schema k=$(k) >> gen/test.log

test-schema:
	ldapsearch -x -h $(call get_ip,$(name)-centos$(k)) -LLL -D 'cn=Manager,cn=config' -b 'cn=subschema' -s base + -w $(LDAP_ROOT_PASSWORD) | grep structuralObjectClass
	ldapsearch -x -h $(call get_ip,$(name)-centos$(k)) -LLL -D 'cn=Manager,dc=mercury,dc=febras,dc=net' -b 'dc=mercury,dc=febras,dc=net' '(uid=username)' structuralObjectClass -w $(LDAP_MANAGER_PASSWORD)
	ldapsearch -x -h $(call get_ip,$(name)-centos$(k)) -LLL -x -b 'ou=people,dc=mercury,dc=febras,dc=net'

build-schema:
	$(eval ip = $(call get_ip,$(server)))
	docker exec $(server) /schema/build.sh

test-client:
	$(eval ip = $(call get_ip,$(server)))
	ldappasswd -h $(call get_ip,$(name)-centos$(k)) -x -D "uid=username,ou=people,dc=mercury,dc=febras,dc=net" -w p@ssw0rd -s 1
	./schema/modify.sh $(call get_ip,$(name)-centos$(k))
	ldapsearch -x -h $(call get_ip,$(name)-centos$(k)) -LLL -D 'cn=Manager,dc=mercury,dc=febras,dc=net' -b 'dc=mercury,dc=febras,dc=net' '(loginShell=*)' -w $(LDAP_MANAGER_PASSWORD) | grep loginShell
	sshpass -p 1 ssh -o "GSSAPIAuthentication no" -o "UserKnownHostsFile /dev/null" -o StrictHostKeyChecking=no -o "VerifyHostKeyDNS no" -t username@$(ip) sudo ls /root || true

prepare_log:
	@echo > gen/full.log
	@echo > gen/test.log
	@tail -f gen/test.log &
	@tail -f gen/full.log | grep "err=[^0]" &

test:
	@make -s prepare_log
	@make -s start n=6 k=6 >> gen/full.log 2>&1
	@make -s start n=5 k=5 >> gen/full.log 2>&1
	@make -s clear >> gen/full.log 2>&1

hello:
	python -m unittest discover -s misc

dclear:
	docker rm -f $(name)-centos5
	docker rm -f -v $(name)-data5
	docker stop $(name)-client5
	docker rm -f $(name)-client5

clear:
	$(call recreate_server,6,$(name))
	$(call recreate_server,5,$(name))

	docker rm -f $(name)-client6 || true
	docker rm -f $(name)-client5 || true

full-clear:
	docker rm -f -v $(name)-centos6 || true
	docker rm -f -v $(name)-centos5 || true

	docker rm $(name)-data6 || true
	docker rm $(name)-data5 || true

	docker rm -f $(name)-client6 || true
	docker rm -f $(name)-client5 || true
