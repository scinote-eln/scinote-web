FROM ruby:3.2.2-bookworm
MAINTAINER SciNote <info@scinote.net>

# additional dependecies
# libreoffice for file preview generation
RUN apt-get update -qq && \
  apt-get install -y --no-install-recommends \
  libjemalloc2 \
  libssl-dev \
  nodejs \
  postgresql-client \
  default-jre-headless \
  poppler-utils \
  librsvg2-2 \
  libvips42 \
  graphviz  \
  libreoffice \
  fonts-droid-fallback \
  fonts-noto-mono \
  fonts-wqy-microhei \
  fonts-wqy-zenhei \
  libfile-mimeinfo-perl \
  chromium-driver \
  yarnpkg && \
  ln -s /usr/lib/x86_64-linux-gnu/libvips.so.42 /usr/lib/x86_64-linux-gnu/libvips.so && \
  rm -rf /var/lib/apt/lists/*

ENV PATH=/usr/share/nodejs/yarn/bin:$PATH

RUN yarn add puppeteer@npm:puppeteer-core 

ENV BUNDLE_PATH /usr/local/bundle/

# create app directory
ENV APP_HOME /usr/src/app
ENV PATH $APP_HOME/bin:$PATH
RUN mkdir $APP_HOME
WORKDIR $APP_HOME

CMD rails s -b 0.0.0.0
