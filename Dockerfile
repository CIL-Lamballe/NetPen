# Build:
#	docker build -t netpen:v0.1-a .
#
# Usage:
# 	docker run --rm -it \
#		--name netpen \
#               --volum $PWD:/opt/netpen \
#		netpen:v0.1-a
#

FROM ubuntu:bionic

LABEL maintainer "abarthel <abarthel@student.42.fr>"

RUN apt update

RUN apt install -yq --no-install-recommends \
	fping \
	inetutils-ping \
	net-tools \
	git \
	nmap


RUN rm -rf /var/lib/apt/lists/*

ENTRYPOINT ["/bin/bash", "-c", "/opt/netpen/netpen.sh"]
