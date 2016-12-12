gen = /home/eab/git/cc/cc-ldap-centos/gen/
misc = /home/eab/git/cc/cc-ldap-centos/misc/
schema = /home/eab/git/cc/cc-ldap-centos/schema/
LDAP_ROOT_PASSWORD=root
LDAP_MANAGER_PASSWORD=manager
AUTHENTICATOR_PASSWORD=secret
LDAP_BASEDN = "dc=mercury,dc=febras,dc=net"
name=cc-ldap

define get_ip
    $(shell docker inspect -f {{.NetworkSettings.IPAddress}} $(1))
endef

define create_backup
	docker images | grep data$(1)-backup > /dev/null || docker rm -f -v data$(1)-backup || true
	docker stop $(2)-server$(1)
	docker commit $(2)-data$(1) data$(1)-backup
	docker start $(2)-server$(1)
endef

define recreate_server
	docker rm -f -v $(2)-server$(1)
	docker rm -f -v $(2)-data$(1)
	docker run --name $(2)-data$(1) -v /data data$(1)-backup true
	docker run -p 888$(1):80  --name $(2)-server$(1) -v $(schema):/schema -v $(gen):/gen --volumes-from $(2)-data$(1) -e LDAP_ROOT_PASSWORD=$(LDAP_ROOT_PASSWORD) -e LDAP_MANAGER_PASSWORD=$(LDAP_MANAGER_PASSWORD) $(2)-dev$(1) &
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
	$(call fix_tangle,schema/schema.sh)

build-server:
	echo ..was entered to build-server $(n) >> gen/test.log
	docker build -f ldap-server/Dockerfile$(n) -t $(name)-dev$(n) .
	echo cc-ldap-server$(n) was built >> gen/test.log
	docker run --name $(name)-data$(n) -v /data busybox true || true
	docker run -p 888$(n):80 --name $(name)-server$(n) -v $(schema):/schema -v $(gen):/gen --volumes-from $(name)-data$(n) -e LDAP_ROOT_PASSWORD=$(LDAP_ROOT_PASSWORD) -e LDAP_MANAGER_PASSWORD=$(LDAP_MANAGER_PASSWORD) $(name)-dev$(n) &
	echo cc-ldap-server$(n) was run >> gen/test.log
	sleep 10
	$(call create_backup,$(n),$(name))
	echo cc-ldap-server$(n) backup was created >> gen/test.log

build-client:
	$(eval ip = $(call get_ip,$(server)))
	docker build -f ldap-client/Dockerfile$(n) -t $(name)-cli$(n) .
	docker run -d --name $(name)-client$(n) -v $(gen):/gen -e LDAP_SERVER=$(ip) -e LDAP_BASEDN=$(LDAP_BASEDN) $(name)-cli$(n)

start:
	echo ..was entered to start $(n) $(k) >> gen/test.log
	docker ps -a | grep $(name)-server$(n) > /dev/null || make build-server n=$(n)
	docker start $(name)-server$(n)
	echo server$(k) was built >> gen/test.log
	sleep 1
	make build-client n=$(n) server=$(name)-server$(k)
	echo client$(n) was built >> gen/test.log
	make build-schema server=$(name)-server$(n)
	echo schema was created >> gen/test.log
	sleep 1
	docker exec -d $(name)-client$(n) bash /root/hosts.sh $(n) $(AUTHENTICATOR_PASSWORD)
	sleep 3
	make test-client server=$(name)-client$(n) k=$(k) >> gen/test.log

build-schema:
	$(eval ip = $(call get_ip,$(server)))
	docker exec $(server) /schema/build.sh

test-client:
	$(eval ip = $(call get_ip,$(server)))
	python schema/test_schema.py $(name)-server$(k) $(call get_ip,$(name)-server$(k)) $(ip) >> gen/test.log 2>&1

build-gui:
	$(eval ip = $(call get_ip,$(server)))
	docker run -p 8889:80 --name cc-ldap-gui -v $(misc):/misc --env PHPLDAPADMIN_HTTPS=false --env PHPLDAPADMIN_LDAP_HOSTS="#PYTHON2BASH:[{'$(ip)': [{'login': [{'bind_id': 'cn=Manager,dc=mercury,dc=febras,dc=net'}]}]}]" --detach osixia/phpldapadmin
	sleep 1
	docker exec -d cc-ldap-gui mv /var/www/phpldapadmin/templates/creation /var/www/phpldapadmin/templates/creation.bak
	docker exec -d cc-ldap-gui mkdir /var/www/phpldapadmin/templates/creation/
	docker exec -d cc-ldap-gui cp -f -r /misc/. /var/www/phpldapadmin/templates/creation/
	docker exec -d cc-ldap-gui chown -R www-data:www-data /var/www/phpldapadmin/templates/creation/
	echo ..phpLDAPadmin gui was built...use http://localhost:8889 to login >> gen/test.log

prepare_log:
ifeq ($(CC_LDAP_CLEAR), true)
	@echo CC_LDAP_CLEAR is true, state will be cleaned
else
	@echo CC_LDAP_CLEAR isn\'t true, state won\'t be cleaned, use \'make clear\'
endif
	@mkdir -p gen
	@echo > gen/full.log
	@echo > gen/test.log
	@tail -f gen/test.log &
	@tail -f gen/full.log | grep "err=[^0]" &

test:
	@make -s prepare_log
	@make -s start n=6 k=6 >> gen/full.log 2>&1
	@make -s build-gui server=$(name)-server6 >> gen/full.log 2>&1
	@make -s start n=5 k=5 >> gen/full.log 2>&1
ifeq ($(CC_LDAP_CLEAR), true)
	@make -s clear >> gen/full.log 2>&1
endif

clear:
	echo -n cleaning was started.. >> gen/test.log
	$(call recreate_server,6,$(name))
	$(call recreate_server,5,$(name))

	docker rm -f $(name)-client6 || true
	docker rm -f $(name)-client5 || true

	docker rm -f cc-ldap-gui || true
	echo ..clients and gui were deleted, servers were recreated without schema >> gen/test.log

full-clear:
	docker rm -f -v $(name)-server6 || true
	docker rm -f -v $(name)-server5 || true

	docker rm -v $(name)-data6 || true
	docker rm -v $(name)-data5 || true

	docker rm -f $(name)-client6 || true
	docker rm -f $(name)-client5 || true

	docker rm -f cc-ldap-gui || true
