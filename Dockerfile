FROM ubuntu:22.10

RUN DEBIAN_FRONTEND=noninteractive apt-get update
RUN --mount=type=cache,target=/var/cache/apt DEBIAN_FRONTEND=noninteractive apt-get -y dist-upgrade
RUN --mount=type=cache,target=/var/cache/apt DEBIAN_FRONTEND=noninteractive apt-get -y install apt-file jq curl make golang build-essential iptables golang-golang-x-tools vim net-tools telnet iproute2 socat bridge-utils strace iputils-ping delve qemu-system-x86 psmisc dhcpcd-base bash-completion

RUN apt-file update

RUN download_url=$(curl -s https://api.github.com/repos/go-swagger/go-swagger/releases/latest | \
	jq -r '.assets[] | select(.name | contains("'"$(uname | tr '[:upper:]' '[:lower:]')"'_amd64")) | .browser_download_url') && \
	curl -o /usr/local/bin/swagger -L'#' "$download_url" && \
	chmod +x /usr/local/bin/swagger

ADD src /src

WORKDIR /src

RUN rm -fv go.sum
RUN go mod tidy
RUN --mount=type=cache,target=/root/.cache/go-build make

RUN ./rolctl completion bash > /usr/share/bash-completion/completions/rolctl
RUN echo 'source /etc/bash_completion' >> /etc/bash.bashrc

EXPOSE 8080/tcp

RUN perl -pni.bak -e 's/localhost//g' appConfig.yml
RUN perl -pni.bak -e 's/enp0s8/eth1/g' appConfig.yml
RUN perl -pni.bak -e 's/port: 8080/port: 80/g' appConfig.yml

RUN	echo ------------------------------------------------- && \
	echo swagger: http://localhost:8080/swagger/index.html && \
	echo -------------------------------------------------

CMD /src/rol > /root/rol-log.txt 2>&1
