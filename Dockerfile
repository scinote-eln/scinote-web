FROM ruby:2.6.3-buster
MAINTAINER BioSistemika <info@biosistemika.com>

# additional dependecies
# libSSL-1.0 is required by wkhtmltopdf binary
# libreoffice for file preview generation
RUN apt-get update -qq && \
  apt-get install -y \
  libjemalloc2 \
  libssl-dev \
  nodejs \
  yarnpkg \
  postgresql-client \
  default-jre-headless \
  poppler-utils \
  sudo graphviz --no-install-recommends \
  libreoffice \
  libfile-mimeinfo-perl && \
  rm -rf /var/lib/apt/lists/*

# heroku tools
RUN wget -O- https://toolbelt.heroku.com/install-ubuntu.sh | sh

ENV BUNDLE_PATH /usr/local/bundle/

# create app directory
ENV APP_HOME /usr/src/app
ENV PATH $APP_HOME/bin:$PATH
RUN mkdir $APP_HOME
WORKDIR $APP_HOME

CMD rails s -b 0.0.0.0
