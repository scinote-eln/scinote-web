# sciNote

![sciNote logo](http://scinote.net/wp-content/uploads/2015/10/logo_sciNote_final.png)

## About

sciNote is an open source electronic lab notebook ([ELN](https://en.wikipedia.org/wiki/Electronic_lab_notebook)) that helps you manage your laboratory work and stores all your experimental data in one place. sciNote is specifically designed for life science students, researchers, lab technicians and group leaders.

## Build & run

sciNote is developed in [Ruby on Rails](http://rubyonrails.org/). It also makes use of [Docker](https://www.docker.com/) technology, so the easiest way to run it is inside Docker containers.

### Quick start

The following are minimal steps needed to start sciNote in development environment:

1. Clone this Git repository onto your development machine.
2. Create a file `config/application.yml`. Populate it with mandatory environmental variables (see [environmental variables](#user-content-environmental-variables)).
3. In sciNote folder, run the following command: `make docker`. This can take a while, since Docker must first pull an image from the Internet, and then also install all neccesary Gems required by sciNote.
4. Once the Docker image is created, run `make cli` command. Once inside the running Docker container, run the following command: `rake db:reset`. This should initialize the database and fill it with (very minimal) seed data.
5. Exit the Docker container by typing `exit`.
6. To start the server, run command `make run`. Wait until the server starts listening on port `3000`.
7. Open your favourite browser and navigate to [http://localhost:3000](http://localhost:3000/). Use the seeded administrator account from [seeds.rb](db/seeds.rb) to login, or sign up for a new account.

### OS-specific Install Instructions

**Debian**

1. Install Docker and add user `1000` to the docker group as described [here](https://docs.docker.com/engine/installation/linux/debian/).
2. Install Docker Compose as described [here](https://docs.docker.com/compose/install/).
3. Follow [Quick Start Guide](#user-content-quick-start) above as user `1000`.

**Mac OS X**

1. Install command line developer tools (there are many resources online, like [this](http://osxdaily.com/2014/02/12/install-command-line-tools-mac-os-x/)).
2. Install Docker Toolbox as described [here](https://docs.docker.com/mac/step_one/).
3. Inside CLI, run `git clone https://github.com/biosistemika/scinote-web.git`.
4. Run Docker Quickstart Terminal (also described [here](https://docs.docker.com/mac/step_one/)).
5. Inside this terminal, navigate to cloned Git folder.
6. Follow the [Quick Start Guide](#user-content-quick-start) above.
7. When opening sciNote in browser, instead of navigating to `localhost:3000`, navigate to `<docker-machine-ip>:3000` (you can get the docker machine IP by running command `docker-machine ip default`).

### Docker structure

The main sciNote application runs in a Docker container called `web`. The database runs in a separate container, called `db`. This database container makes use of a special, persistent container called `dbdata`.

### Commands

Call `make` commands to build Docker images and build Rails environment, including database.

Following commands are available:

| Command        | Description                                                                                     |
|----------------|-------------------------------------------------------------------------------------------------|
| `make docker`  | Downloads the Docker image and build Gems. This should be called whenever `Gemfile` is changed. |
| `make db-cli`  | Runs a `/bin/bash` inside the `db` container.                                                   |
| `make run`     | Runs the `db` container & starts the Rails server in `web` container.                           |
| `make start`   | Runs the `db` container & starts the Rails server in `web` container in background.             |
| `make stop`    | Stops the `db` & `web` containers.                                                              |
| `make cli`     | Runs a `/bin/bash` inside the `web` container.                                                  |
| `make tests`   | Execute all Rails tests.                                                                        |
| `make console` | Enters the Rails console in `web` container.                                                    |
| `make export`  | Zips the head of this Git repository into a `.tar.gz` file.                                     |

## Environmental variables

sciNote reads configuration parameters from system environment parameters. On production servers, this can be simply be system environmental variables, while for development, a file `config/application.yml` can be created to specify those variables.

The following table describes all available environmental variables for sciNote server.

| Variable                | Mandatory | Description |
|-------------------------|-----------|-------------|
| SECRET_KEY_BASE         | Yes       | Random hash for Rails encryption. Can be generated by running `rake secret`. |
| PAPERCLIP_STORAGE       | Yes       | Set to `'s3'` to store files on Amazon S3, or `'filesystem'` to store files on local server. If storing on S3, additional parameters need to be specified. |
| AWS_SECRET_ACCESS_KEY   | No*       | If storing files on Amazon S3, this must contain access key for accessing AWS S3 API. |
| AWS_ACCESS_KEY_ID       | No*       | If storing files on Amazon S3, this must contain access key ID for AWS S3. |
| S3_BUCKET               | No*       | If storing files on Amazon S3, this must contain S3 bucket on which files are stored. |
| AWS_REGION              | No*       | If storing files on Amazon S3, this must contain the AWS region. |
| PAPERCLIP_DIRECT_UPLOAD | No*       | If storing files on Amazon S3, this must be set either to `1` (to upload files directly from client-side to S3, without passing through sciNote server) or to `0` (to upload files to S3 through sciNote server). |
| MAIL_FROM               | Yes       | The **from** address for emails sent from sciNote. |
| MAIL_REPLYTO            | Yes       | The **reply to** address for emails sent from sciNote. |
| SMTP_ADDRESS            | Yes       | The server address of the SMTP mailer used for delivering emails generated in sciNote. |
| SMTP_PORT               | Yes       | The port of the SMTP server. Defaults to `587`. |
| SMTP_DOMAIN             | Yes       | The server domain of the SMTP mailer used for delivering emails generated in sciNote. |
| SMTP_USERNAME           | Yes       | The username for SMTP mailer used for delivering emails generated in sciNote. |
| SMTP_PASSWORD           | Yes       | The password for SMTP mailer used for delivering emails generated in sciNote. |
| MAIL_SERVER_URL         | Yes       | The root URL address of the actual sciNote server. This is used in sent emails to redirect user to the correct sciNote server URL. Defaults to `localhost`. |
| PAPERCLIP_HASH_SECRET   | Yes       | Random key for generating Paperclip hash key for URLs. Can be generated via following Ruby function: `SecureRandom.base64(128)`. |
| ENABLE_TUTORIAL         | Yes       | Whether to display tutorial (and auto-generate demo project) to first-time users. Defaults to `false` on development, and to `true` on production. |

## Rake tasks

### Delayed jobs

sciNote uses [delayed jobs](https://github.com/tobi/delayed_job) library to do background processing, mostly for the following tasks:
* Sending emails,
* Extracting text from uploaded files (*full-text* search).

Best option to run delayed jobs is inside a worker process. To start a background worker process that will execute delayed jobs, run the following command:
```
rake jobs:work
```
To clear all currently queued jobs, you can use the following command:
```
rake jobs:clear
```
**Warning!** This is not advised to do on production environments.

### Adding users

To simplify adding of new users to the system, couple of special `rake` tasks have been created.

The first, `rake db:add_user` simply queries all the information for a specific user via STDIN, and then proceeds to create the user.

The second task, `rake db:load_users[file_path,create_orgs]` takes 2 parameters as an input:
* Path to `.yml` file containing list of users & organizations to be added. The YAML file needs to be structured properly - field names must match those in the database, users need to have a name `user_<id>`, and organizations name `org_<id>`. For an example load users file, see [db/load_users_template.yml](db/load_users_template.yml) file.
* A boolean ('true' or 'false') whether to create individual organizations for each user or not.

Both of those rake actions include all database operations inside a transaction, so as long as any error happens during the process, database will be unaffected.

### Generating fake data

For testing purposes, two special tasks that will populate the database with randomized, fake data, have been implemented.

The first, `rake db:fake:generate`, will add fake data to an existing database. Since the algorithm that generates randomized data relies heavily on querying existing entries in database, use of this task is **not advisable**.

It is **much better** to use `rake db:fake` task, that will drop the database first, recreate it, and populate it with fake data afterwards.

### Web statistics

To check current login statistics of registered users, use `rake web_stats:login` task.

### Clearing data

Execute `rake data:clean_temp_files` to remove all temporary files. Temporary files are used when importing samples.
Execute `rake data:clean_unconfirmed_users` to remove all users that registered, but never confirmed their email.
Calling `rake data:clean` will execute both above tasks.

## Mailer

sciNote needs a configured SMTP mail server to work properly. See [environmental variables](#user-content-environmental-variables) for configuration of the mailer.

## Deploy onto Heroku

Before deploying to Heroku, install heroku client as describe on offical website. To use existing heroku application, add new git remote repository.

```
git remote add heroku git@heroku.com:my-random-app-name.git
```

Or create new heroku application by executing following command.

```
heroku create
```

Add additional heroku buildpacks in the same order as specified in [.buildpacks](.buildpacks):

```
heroku buildpacks:add --index <i> <buildpack>
```

e.g. for adding graphviz write:

```
heroku buildpacks:add --index 2 https://github.com/weibeld/heroku-buildpack-graphviz.git
```

Before pushing to heroku master branch, some environmental variables should be set.

### Heroku environmental variables

For deployment of sciNote onto Heroku, additional environmental variables need to be specified.

| Variable                 | Mandatory | Description                                                                                |
|--------------------------|-----------|--------------------------------------------------------------------------------------------|
| SKYLIGHT_AUTHENTICATION  | No        | The API key for [Skylight](https://www.skylight.io/) code profiler, if choosing to use it. |
| LANG                     | Yes       | The default localization language (e.g. `en_US.UTF-8`).                                    |
| RAILS_ENV                | Yes       | Rails environment: `production`, `test` or `development`.                                  |
| RACK_ENV                 | Yes       | Rack environment: `production`, `test` or `development`.                                   |
| RAILS_SERVE_STATIC_FILES | Yes       | Whether to serve static files. Must be set to `enabled`.                                   |
| WEB_CONCURRENCY          | Yes       | The concurrency of the server. See Heroku specifications for details.                      |
| MAX_THREADS              | Yes       | The max. number of threads. See Heroku specifications for details.                         |
| PORT                     | Yes       | The port on which the application should run. See Heroku specifications for details.       |
| S3_HOST_NAME             | No*       | If storing files on Amazon S3, this must contain the S3 service host name.                 |
| RAILS_FORCE_SSL          | Yes       | If set to `1`, enforce SSL communication on all levels of application.                     |
| DATABASE_URL             | Yes       | Full URL for connecting to PostgreSQL database.                                            |

## Testing

In current version, only *model* tests are implemented for sciNote. To execute them, call `rake test:models`.

## Contributing

For contributing, see [CONTRIBUTING.md](CONTRIBUTING.md).

## License

sciNote is developed and maintained by BioSistemika USA, LLC, under [Mozilla Public License Version 2.0](LICENSE.txt).

See [LICENSE-3RD-PARTY.txt](LICENSE-3RD-PARTY.txt) for licenses of included third-party libraries.
