.PHONY: docker

docker:
	docker network create lab || true
	docker build -t rol .
	ID=$(shell docker run -p8080:8080/tcp --privileged -d rol); \
	   docker network connect lab $$ID && \
	   docker exec -it $$ID /bin/bash && \
	   echo "Stopping container ..."; \
	   docker stop $$ID
