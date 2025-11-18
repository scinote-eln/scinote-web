FROM ruby:3.3-bookworm
MAINTAINER SciNote <info@scinote.net>

ARG TIKA_DIST_URL="https://dlcdn.apache.org/tika/3.2.3/tika-app-3.2.3.jar"
ENV TIKA_PATH=/usr/local/bin/tika-app.jar

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
  chromium \
  chromium-sandbox \
  yarnpkg && \
  wget -O $TIKA_PATH $TIKA_DIST_URL && \
  chmod +x $TIKA_PATH && \
  ln -s /usr/lib/x86_64-linux-gnu/libvips.so.42 /usr/lib/x86_64-linux-gnu/libvips.so && \
  rm -rf /var/lib/apt/lists/*

ENV PATH=/usr/share/nodejs/yarn/bin:$PATH

RUN yarn add npm:puppeteer-core@24.10.0

ENV BUNDLE_PATH /usr/local/bundle/

# create app directory
ENV APP_HOME /usr/src/app
ENV PATH $APP_HOME/bin:$PATH
RUN mkdir $APP_HOME
RUN adduser --uid 1000 scinote
RUN chown scinote:scinote $APP_HOME
USER scinote
ENV CHROMIUM_PATH=$APP_HOME/bin/chromium
WORKDIR $APP_HOME

CMD rails s -b 0.0.0.0
