FROM ubuntu:14.04

RUN apt-get update
RUN apt-get install -y git
RUN apt-get install -y openjdk-7-jdk openjdk-7-doc openjdk-7-jre-lib
RUN apt-get install -y maven 
RUN apt-get install -y ruby-dev gcc rpm dpkg-dev
RUN gem install fpm
RUN apt-get install -y nginx

ENV URL="http://localhost:80"
EXPOSE 80

ADD install.sh /

# webhookd
ADD https://github.com/ncarlier/webhookd/releases/download/v0.0.3/webhookd-linux-amd64-v0.0.3.tar.gz /
RUN tar xvzf webhookd-linux-amd64-v0.0.3.tar.gz
RUN mv webhookd /usr/bin
RUN mkdir -p /scripts/github
ADD build.sh /scripts/github/
RUN chmod +x /scripts/github/build.sh

WORKDIR /
ADD run.sh /
RUN chmod +x /run.sh

ENTRYPOINT exec /run.sh
