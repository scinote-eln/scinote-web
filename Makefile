APP_HOME="/usr/src/app"
DB_IP=$(shell docker inspect web_db_1 | grep -m 1 "\"IPAddress\": " | awk '{ match($$0, /"IPAddress": "([0-9\.]*)",/, a); print a[1] }')

all: docker database

heroku:
	@heroku buildpacks:remove https://github.com/ddollar/heroku-buildpack-multi.git
	@heroku buildpacks:set https://github.com/ddollar/heroku-buildpack-multi.git
	@echo "Set environment variables, DATABASE_URL, RAILS_SERVE_STATIC_FILES, RAKE_ENV, RAILS_ENV, SECRET_KEY_BASE, SKYLIGHT_AUTHENTICATION"

docker:
	@docker-compose build

docker-production:
	@docker-compose -f docker-compose.production.yml build

db-cli:
	@$(MAKE) rails cmd="rails db"

db-load-dump:
	@$(MAKE) rails cmd="rake db:drop db:create;pg_restore --verbose --clean --no-acl --no-owner -h $(DB_IP) -p 5432 -U postgres -d scinote_development latest.dump"

database:
	@$(MAKE) rails cmd="rake db:create db:setup db:migrate"

rails:
	@docker-compose run --rm web $(cmd)

rails-production:
	@docker-compose -f docker-compose.production.yml run --rm web $(cmd)

run:
	rm tmp/pids/server.pid || true
	@docker-compose up -d
	@docker attach $(shell docker-compose ps web | grep "rails s" | awk '{ print $$1; }')

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

log:
	@docker-compose web log

status:
	@docker-compose ps

export:
	@git checkout-index -a -f --prefix=scinote/
	@tar -zcvf scinote-$(shell git rev-parse --short HEAD).tar.gz scinote
	@rm -rf scinote
