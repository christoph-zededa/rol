.PHONY: docker

docker:
	docker build -t rol . && docker run -p8080:8080/tcp -it --privileged rol /bin/bash
