FROM ubuntu:22.10

RUN DEBIAN_FRONTEND=noninteractive apt-get update
RUN DEBIAN_FRONTEND=noninteractive apt-get -y dist-upgrade
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install apt-file jq curl make golang build-essential iptables golang-golang-x-tools vim

RUN apt-file update

RUN download_url=$(curl -s https://api.github.com/repos/go-swagger/go-swagger/releases/latest | \
	jq -r '.assets[] | select(.name | contains("'"$(uname | tr '[:upper:]' '[:lower:]')"'_amd64")) | .browser_download_url') && \
	curl -o /usr/local/bin/swagger -L'#' "$download_url" && \
	chmod +x /usr/local/bin/swagger

ADD src /src

WORKDIR /src

RUN make
