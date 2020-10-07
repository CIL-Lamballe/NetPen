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

RUN DEBIAN_FRONTEND=noninteractive apt install -yq --no-install-recommends \
	fping \
	inetutils-ping \
	net-tools \
	git \
	nmap \
	python3 \
	python3-pip \
	ca-certificates \
	tzdata

RUN rm -rf /var/lib/apt/lists/*

RUN echo "Europe/Paris" | tee /etc/timezone \
 && dpkg-reconfigure --frontend noninteractive tzdata

#VOLUME /opt/netpen/ /opt/netpen/assets/ /opt/netpen/assets/dependencies /opt/netpen/assets/dependencies/theHarvester
#VOLUME /opt/netpen/

WORKDIR /opt/netpen/

ENV TERM=xterm-256color

#ENTRYPOINT ["/bin/bash", "/opt/netpen/netpen.sh"]

# Debug
ENTRYPOINT ["/bin/bash"]
