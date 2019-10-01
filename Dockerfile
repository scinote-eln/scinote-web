FROM ruby:2.6.4-buster
MAINTAINER BioSistemika <info@biosistemika.com>

# additional dependecies
# libSSL-1.0 is required by wkhtmltopdf binary
# libreoffice for file preview generation
RUN apt-get update -qq && \
  apt-get install -y \
  libjemalloc2 \
  libssl-dev \
  nodejs \
  npm \
  postgresql-client \
  default-jre-headless \
  poppler-utils \
  librsvg2-2 \
  libvips42 \
  sudo graphviz --no-install-recommends \
  libreoffice \
  libfile-mimeinfo-perl \
  chromium-driver && \
  npm install -g yarn && \
  ln -s /usr/lib/x86_64-linux-gnu/libvips.so.42 /usr/lib/x86_64-linux-gnu/libvips.so && \
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
