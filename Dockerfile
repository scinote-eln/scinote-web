FROM ruby:2.5.5
MAINTAINER BioSistemika <info@biosistemika.com>

# Get version of Debian (lsb_release substitute) and save it to /tmp/lsb_release for further commands
RUN cat /etc/os-release | grep -Po "VERSION=.*\(\K\w+" | tee /tmp/lsb_release

# Add Debian stretch backports repository
RUN echo "deb http://http.debian.net/debian $(cat /tmp/lsb_release)-backports main" \
  | tee /etc/apt/sources.list.d/$(cat /tmp/lsb_release)-backports.list

# additional dependecies
# libSSL-1.0 is required by wkhtmltopdf binary
# libreoffice for file preview generation
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
  apt-get install -y --no-install-recommends -t $(cat /tmp/lsb_release)-backports libreoffice && \
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
