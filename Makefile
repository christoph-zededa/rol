.PHONY: id stop attach all

all: .container_project attach

.container_id:
	docker build -t rol .
	$(eval ID=$(shell docker run -p8080:80/tcp --privileged -d --name rol rol))
	echo $(ID) > .container_id

.container_network: .container_id
	$(eval ID=$(shell cat .container_id))
	docker network create --subnet 10.100.0.0/24 --opt com.docker.network.bridge.name=lab_net lab || true
	docker network ls -f name=lab -q > .container_network
	docker network connect lab $(ID)
	sleep 5

.container_project: .container_network .container_id
	$(eval ID=$(shell cat .container_id))
	$(eval OUT=$(shell docker exec $(ID) curl -X 'POST' \
		'http://localhost:80/api/v1/project/' \
		-H 'accept: application/json' \
		-H 'Content-Type: application/json' \
		-d '{ "name": "project", "subnet": "10.100.0.2" }' | jq .))
	echo '$(OUT)' > .container_project
	docker exec $(ID) ip link add client1_br type veth peer client1
	docker exec $(ID) ip link set client1_br up
	docker exec $(ID) brctl addif rol.br.project client1_br
	docker exec $(ID) ip link set client1 up
	docker exec $(ID) dhtest -i client1 -V

.container_tftp: .container_network
	$(eval ID=$(shell cat .container_id))
	$(eval TFTP=$(shell cat .container_project | jq -r .TFTPServerID))
	$(eval OUT=$(shell docker exec $(ID) curl -X 'POST' \
		"http://localhost:80/api/v1/tftp/$(TFTP)/path/" \
		-H 'accept: application/json' \
		-H 'Content-Type: application/json' \
		-d '{ "actualPath": "/etc/passwd", "virtualPath": "passwd" }'))
	echo '$(OUT)' > .container_tftp
	docker exec $(ID) curl tftp://10.100.0.1/passwd

stop:
	$(eval ID=$(shell cat .container_id))
	test -n "$(ID)" && docker rm -f $(ID) || true
	docker rm -f rol || true
	rm -f .container_id
	rm -f .container_project
	rm -f .container_tftp
	docker network rm lab || true
	rm -f .container_network

id: .container_id
	$(eval ID=$(shell cat .container_id))
	@echo $(ID)

attach: .container_id
	$(eval ID=$(shell cat .container_id))
	docker exec -it $(ID) /bin/bash

