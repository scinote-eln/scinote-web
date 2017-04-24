FROM ruby:2.3.3
MAINTAINER BioSistemika <info@biosistemika.com>

# additional dependecies
RUN apt-get update -qq && \
  apt-get install -y \
  nodejs \
  postgresql-client \
  default-jre-headless \
  unison \
  sudo graphviz --no-install-recommends \
  libfile-mimeinfo-perl && \
  rm -rf /var/lib/apt/lists/*

# heroku tools
RUN wget -O- https://toolbelt.heroku.com/install-ubuntu.sh | sh

ENV BUNDLE_PATH /usr/local/bundle/

# create app directory
ENV APP_HOME /usr/src/app
RUN mkdir $APP_HOME
WORKDIR $APP_HOME

CMD rails s -b 0.0.0.0
