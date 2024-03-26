APP_HOME="/usr/src/app"
DB_IP=$(shell docker inspect scinote_db_development | grep "\"IPAddress\": " | awk '{ match($$0, /"IPAddress": "([0-9\.]*)",/, a); print a[1] }')
BUILD_TIMESTAMP=$(shell date +%s)

define PRODUCTION_CONFIG_BODY
SECRET_KEY_BASE=$(shell openssl rand -hex 64)
DATABASE_URL=postgresql://postgres:mysecretpassword@db/scinote_production
ACTIVESTORAGE_SERVICE=local
ENABLE_RECAPTCHA=false
ENABLE_USER_CONFIRMATION=false
ENABLE_USER_REGISTRATION=false
DEFACE_ENABLED=false
endef
export PRODUCTION_CONFIG_BODY


all: docker database

heroku:
	@heroku buildpacks:remove https://github.com/ddollar/heroku-buildpack-multi.git
	@heroku buildpacks:set https://github.com/ddollar/heroku-buildpack-multi.git
	@echo "Set environment variables, DATABASE_URL, RAILS_SERVE_STATIC_FILES, RAKE_ENV, RAILS_ENV, SECRET_KEY_BASE"

docker:
	@docker-compose build

docker-ci:
	@docker-compose --progress plain build web

docker-production:
	@docker-compose -f docker-compose.production.yml build --build-arg BUILD_TIMESTAMP=$(BUILD_TIMESTAMP)

config-production:
ifeq (production.env,$(wildcard production.env))
	$(error File production.env already exists!)
endif
	@echo "$$PRODUCTION_CONFIG_BODY" > production.env ;

db-cli:
	@$(MAKE) rails cmd="rails db"

db-load-dump:
	@$(MAKE) rails cmd="rake db:drop db:create;pg_restore --verbose --clean --no-acl --no-owner -h $(DB_IP) -p 5432 -U postgres -d scinote_development latest.dump"

database:
	@$(MAKE) rails cmd="rake db:create db:setup db:migrate"

database-production:
	@$(MAKE) rails-production cmd="bash -c 'while ! nc -z db 5432; do sleep 1; done; rake db:create && rake db:migrate && rake db:seed'"

deface:
	@$(MAKE) rails cmd="rake deface:precompile"

rails:
	@docker-compose run --rm web $(cmd)

rails-production:
	@docker-compose -f docker-compose.production.yml run --rm web $(cmd)

run:
	rm -f tmp/pids/server.pid
	@docker-compose up -d
	@docker attach scinote_web_development

start:
	@docker-compose start

stop:
	@docker-compose stop

worker:
	@$(MAKE) rails cmd="rake jobs:work export WORKER=1"

cli:
	@$(MAKE) rails cmd="/bin/bash"

cli-production:
	@$(MAKE) rails-production cmd="/bin/bash"

unit-tests:
	@$(MAKE) rails cmd="bundle exec rspec"

integration-tests:
	@$(MAKE) rails cmd="bundle exec cucumber"

tests-ci:
	@docker-compose run --rm web bash -c "bundle install"
	@docker-compose run -e ENABLE_EMAIL_CONFIRMATIONS=false \
						-e MAIL_FROM=MAIL_FROM \
						-e MAIL_REPLYTO=MAIL_REPLYTO \
						-e RAILS_ENV=test \
						-e MAIL_SERVER_URL=http://localhost:3000 \
						-e ENABLE_RECAPTCHA=false \
						-e ENABLE_USER_CONFIRMATION=false \
						-e ENABLE_USER_REGISTRATION=true \
						-e CORE_API_RATE_LIMIT=1000000 \
						-e PROTOCOLS_IO_ACCESS_TOKEN=PROTOCOLS_IO_ACCESS_TOKEN \
						-e ENABLE_WEBHOOKS=true \
						--rm web bash -c "rake db:create && rake db:migrate && bundle exec rspec ./spec/"

console:
	@$(MAKE) rails cmd="rails console"

console-production:
	@$(MAKE) rails-production cmd="rails console"

log:
	@docker-compose web log

status:
	@docker-compose ps

export:
	@git checkout-index -a -f --prefix=scinote/
	@tar -zcvf scinote-$(shell git rev-parse --short HEAD).tar.gz scinote
	@rm -rf scinote
