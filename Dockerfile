FROM ubuntu:14.04

RUN apt-get update
RUN apt-get install -y git
RUN apt-get install -y openjdk-7-jdk openjdk-7-doc openjdk-7-jre-lib
RUN apt-get install -y maven 
RUN apt-get install -y ruby-dev gcc rpm dpkg-dev
RUN gem install fpm
RUN apt-get install -y nginx

ENV URL="http://localhost:80"

ADD install.sh /

RUN mkdir -p /build
ADD build.sh /build/
ADD simple-webserver.py /build/
RUN chmod +x /build/build.sh

WORKDIR /
ADD run.sh /
RUN chmod +x /run.sh

ENTRYPOINT exec /run.sh
