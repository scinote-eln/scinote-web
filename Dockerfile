FROM rails:4.2.5
MAINTAINER BioSistemika <info@biosistemika.com>

# additional dependecies
RUN apt-get update -qq && apt-get install -y default-jre-headless unison sudo graphviz --no-install-recommends && rm -rf /var/lib/apt/lists/*

# heroku tools
RUN wget -O- https://toolbelt.heroku.com/install-ubuntu.sh | sh

# install gems
COPY Gemfile* /tmp/
WORKDIR /tmp
RUN bundle install

# create app directory
ENV APP_HOME /usr/src/app
RUN mkdir $APP_HOME
WORKDIR $APP_HOME

# container user
RUN groupadd scinote
RUN useradd -ms /bin/bash -g scinote scinote
USER scinote

CMD rails s -b 0.0.0.0
