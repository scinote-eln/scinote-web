# Contributing to *sciNote*

We'd love to hear your feedback. *sciNote* was developed with the aim to be a collaborative open-source project, so please open new issues describing any bugs, feature requests or suggestions that you have.

**DISCLAIMER: We firmly believe that our vision for the future of sciNote is the right one, therefore we reserve the right to accept OR reject any reported bugs and opened pull requests.**

### Non code-related feedback

This GitHub repository is a place to discuss *sciNote* source code. If you have any questions regarding usage of *sciNote*, tutorials, etc., please contact our support by sending an email to [info@scinote.net](mailto:info@scinote.net).

If we receive a lot of similar feedback, we will try to provide better instructions / readme-s / tutorials.

## Issue Reporting

For issue reporting, please visit our [Jira page](https://scinote.atlassian.net). It is an open source Jira that requires no sign-up (you can report issues as anonymous user). Detailed instructions about issue reporting are documented there.

## Pull Requests

We will consider high quality pull requests.

### Things to Keep in Mind

1. Whenever pull request requires additional work to be done on the client side (e.g. including a new Gem will requires calling of `make build`, adding database changes requires `rake db:migrate` task, ...), please specify that in the pull request description.

2. Whenever implementing changes to the database layer, make sure to apply changes on the following locations:
  * Code change/s inside `ActiveRecord`-s as needed,
  * Code database migrations that need to be:
    * **reversible** - this can be done by using `up` and `down` methods.
  * Fix model tests so they aren't potentially broken and (optionally) add new tests that will test the new functionality. Calling `rake test:models` **must result in 0 errors & 0 failures**.
  * *(related to model tests)* Fix the fixtures so they are in lieu with the database changes.
  * Fix the fake seeding rake task - [db_fake_data.rake](lib/tasks/db_fake_data.rake), so it will auto-generate potential new changes.
  * Fix the demo tutorial seeding method - [first_time_data_generator.rb](app/utilities/first_time_data_generator.rb), so it will auto-generate potential new changes.
  * When merging a database-related pull request, always make sure that [schema.rb](db/schema.rb) gets updated. This often means editing `schema.rb` by hand. Make sure all changes are persisted into this document, and that the schema version (`ActiveRecord::Schema.define(version: <version>)`) equals to the last migration in the application.
