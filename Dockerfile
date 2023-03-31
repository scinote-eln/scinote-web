FROM ruby:2.7.6-bullseye
MAINTAINER BioSistemika <info@biosistemika.com>

ARG WKHTMLTOPDF_PACKAGE_URL=https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6-1/wkhtmltox_0.12.6-1.buster_amd64.deb

# additional dependecies
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
  fonts-droid-fallback \
  fonts-noto-mono \
  fonts-wqy-microhei \
  fonts-wqy-zenhei \
  libfile-mimeinfo-perl \
  chromium-driver && \
  wget -q -O /tmp/wkhtmltox_amd64.deb $WKHTMLTOPDF_PACKAGE_URL && \
  apt-get install -y /tmp/wkhtmltox_amd64.deb && \
  rm /tmp/wkhtmltox_amd64.deb && \
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
