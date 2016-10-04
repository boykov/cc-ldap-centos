tangle: docs/index.org
	@emacsclient -s serverN --eval "(progn (find-file \"docs/index.org\") (eab/tangle-init))" > /dev/null
	chmod 0755 ldap-server/run.sh

build-server:
	cd ldap-server && docker build -t cc-ldap-dev5 .
	docker run --name cc-ldap-data5 -v /data busybox true || true
	docker run --name cc-ldap-centos5 --volumes-from cc-ldap-data5 cc-ldap-dev5

test:
	docker start cc-ldap-centos5
	$(eval IPcentos5 := $(shell docker inspect -f {{.NetworkSettings.IPAddress}} cc-ldap-centos5))
	sleep 1
	cd ldap-server && ldapadd -h $(IPcentos5) -x -D 'cn=Manager,dc=tuleap,dc=local' -w manager -f bob.ldif || true
	cd ldap-server && ldapadd -h $(IPcentos5) -x -D 'cn=Manager,dc=tuleap,dc=local' -w manager -f admin.ldif || true
	ldapsearch -x -h $(IPcentos5) -LLL -D 'cn=Manager,cn=config' -b 'dc=tuleap,dc=local' '*' -w root

clear:
	docker rm -f -v cc-ldap-centos5
	docker rm cc-ldap-data5
