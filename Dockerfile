FROM ruby:2.6.4-buster
MAINTAINER BioSistemika <info@biosistemika.com>

RUN wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | apt-key add - && \
    echo 'deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main' >> /etc/apt/sources.list && \
    wget -O /usr/bin/chromedriver_linux64.zip https://chromedriver.storage.googleapis.com/77.0.3865.40/chromedriver_linux64.zip && \
    unzip /usr/bin/chromedriver_linux64.zip -d /usr/bin/

# additional dependecies
# libSSL-1.0 is required by wkhtmltopdf binary
# libreoffice for file preview generation
RUN curl -sL https://deb.nodesource.com/setup_8.x | bash - && \
  apt-get update -qq && \
  apt-get install -y \
  # libjemalloc2 \
  # libssl-dev \
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
  google-chrome-stable && \
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
