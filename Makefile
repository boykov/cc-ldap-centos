tangle: docs/index.org
	@emacsclient -s serverN --eval "(progn (find-file \"docs/index.org\") (eab/tangle-init))" > /dev/null
	chmod 0755 ldap-server/run.sh

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

start:
	docker start cc-ldap-centos5
	docker start cc-ldap-centos6
	sleep 1

test: start
	$(eval IPcentos5 = $(shell docker inspect -f {{.NetworkSettings.IPAddress}} cc-ldap-centos5))
	echo $(IPcentos5)
	cd ldap-server && ldapadd -h $(IPcentos5) -x -D 'cn=Manager,dc=tuleap,dc=local' -w manager -f bob.ldif || true
	cd ldap-server && ldapadd -h $(IPcentos5) -x -D 'cn=Manager,dc=tuleap,dc=local' -w manager -f admin.ldif || true
	ldapsearch -x -h $(IPcentos5) -LLL -D 'cn=Manager,cn=config' -b 'dc=tuleap,dc=local' '*' -w root

	$(eval IPcentos6 := $(shell docker inspect -f {{.NetworkSettings.IPAddress}} cc-ldap-centos6))
	echo $(IPcentos6)
	cd ldap-server && ldapadd -h $(IPcentos6) -x -D 'cn=Manager,dc=tuleap,dc=local' -w manager -f bob.ldif || true
	cd ldap-server && ldapadd -h $(IPcentos6) -x -D 'cn=Manager,dc=tuleap,dc=local' -w manager -f admin.ldif || true
	ldapsearch -x -h $(IPcentos6) -LLL -D 'cn=Manager,cn=config' -b 'dc=tuleap,dc=local' '*' -w root

clear:
	docker rm -f -v cc-ldap-centos5
	docker rm cc-ldap-data5
	docker rm -f -v cc-ldap-centos6
	docker rm cc-ldap-data6
