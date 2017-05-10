APP_HOME="/usr/src/app"
DB_IP=$(shell docker inspect web_db_1 | grep -m 1 "\"IPAddress\": " | awk '{ match($$0, /"IPAddress": "([0-9\.]*)",/, a); print a[1] }')

define PRODUCTION_CONFIG_BODY
SECRET_KEY_BASE=$(shell openssl rand -hex 64)
PAPERCLIP_HASH_SECRET=$(shell openssl rand -base64 128 | tr -d '\n')
DATABASE_URL=postgresql://postgres@db/scinote_production
PAPERCLIP_STORAGE=filesystem
ENABLE_TUTORIAL=true
ENABLE_RECAPTCHA=false
ENABLE_USER_CONFIRMATION=false
ENABLE_USER_REGISTRATION=true
DEFACE_ENABLED=false
endef
export PRODUCTION_CONFIG_BODY

all: docker database

heroku:
	@heroku buildpacks:remove https://github.com/ddollar/heroku-buildpack-multi.git
	@heroku buildpacks:set https://github.com/ddollar/heroku-buildpack-multi.git
	@echo "Set environment variables, DATABASE_URL, RAILS_SERVE_STATIC_FILES, RAKE_ENV, RAILS_ENV, SECRET_KEY_BASE, SKYLIGHT_AUTHENTICATION"

docker:
	@docker-compose build

docker-production:
	@docker-compose -f docker-compose.production.yml build

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
	rm tmp/pids/server.pid || true
	@docker-compose up -d
	@docker attach scinote_web_development

start:
	@docker-compose start

stop:
	@docker-compose stop

worker:
	@$(MAKE) rails cmd="rake jobs:work"

cli:
	@$(MAKE) rails cmd="/bin/bash"

cli-production:
	@$(MAKE) rails-production cmd="/bin/bash"

tests:
	@$(MAKE) rails cmd="rake test"

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
