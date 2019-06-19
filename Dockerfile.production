FROM ruby:2.5.5
MAINTAINER BioSistemika <info@biosistemika.com>

RUN echo deb "http://http.debian.net/debian stretch-backports main" >> /etc/apt/sources.list

# additional dependecies
# libSSL-1.0 is required by wkhtmltopdf binary
# libreoffice for file preview generation
RUN curl -sL https://deb.nodesource.com/setup_8.x | bash - && \
  apt-get update -qq && \
  apt-get install -y \
  libjemalloc1 \
  libssl1.0-dev \
  nodejs \
  groff-base \
  awscli \
  postgresql-client \
  netcat \
  default-jre-headless \
  sudo graphviz --no-install-recommends \
  libfile-mimeinfo-perl && \
  apt-get install -y --no-install-recommends -t stretch-backports libreoffice && \
  npm install -g yarn && \
  rm -rf /var/lib/apt/lists/*

ENV RAILS_ENV production

# install gems
COPY Gemfile* /usr/src/bundle/
COPY addons /usr/src/bundle/addons
WORKDIR /usr/src/bundle
RUN bundle install

# create app directory
ENV APP_HOME /usr/src/app
RUN mkdir $APP_HOME
WORKDIR $APP_HOME
COPY . .
RUN rm -f $APP_HOME/config/application.yml $APP_HOME/production.env

RUN DATABASE_URL=postgresql://postgres@db/scinote_production \
  PAPERCLIP_HASH_SECRET=dummy \
  SECRET_KEY_BASE=dummy \
  DEFACE_ENABLED=true \
  bash -c "rake assets:precompile && rake deface:precompile"

CMD rails s -b 0.0.0.0
