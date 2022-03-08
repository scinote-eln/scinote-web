FROM ruby:2.5.5
MAINTAINER BioSistemika <info@biosistemika.com>

# additional dependecies
# libSSL-1.0 is required by wkhtmltopdf binary
RUN curl -sL https://deb.nodesource.com/setup_8.x | bash - && \
  apt-get update -qq && \
  apt-get install -y \
  libjemalloc1 \
  libssl1.0-dev \
  nodejs \
  postgresql-client \
  default-jre-headless \
  unison \
  sudo graphviz --no-install-recommends \
  libfile-mimeinfo-perl && \
  npm install -g yarn && \
  rm -rf /var/lib/apt/lists/*

# heroku tools
RUN wget -O- https://toolbelt.heroku.com/install-ubuntu.sh | sh

ENV BUNDLE_PATH /usr/local/bundle/

# create app directory
ENV APP_HOME /usr/src/app
RUN mkdir $APP_HOME
WORKDIR $APP_HOME

CMD rails s -b 0.0.0.0
