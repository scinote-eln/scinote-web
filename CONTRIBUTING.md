# Contributing to *sciNote*

We'd love to hear your feedback. *sciNote* was developed with the aim to be a collaborative open-source project, so please open new issues describing any bugs, feature requests or suggestions that you have.

**DISCLAIMER: We firmly believe that our vision for the future of sciNote is the right one, therefore we reserve the right to accept OR reject any reported bugs and opened pull requests.**

### Non code-related feedback

This GitHub repository is a place to discuss *sciNote* source code. If you have any questions regarding usage of *sciNote*, tutorials, etc., please contact our support by sending an email to [info@scinote.net](mailto:info@scinote.net).

If we receive a lot of similar feedback, we will try to provide better instructions / readme-s / tutorials.

## Issue Reporting

Before creating new issue make sure that you understand what should be expected
result of some functionality. Then search for issues if your issue was already
reported by someone else. Searching includes both issues title and description,
so it should be easy to locate the potentially existing issues. Mind that some
terms might have synonyms, so try to include those in your search as well. Make
sure to include both open and closed issues in your search.

### 1. Issue description

When creating new issue, the **issue description** *must* describe following information:

1. Summary: Summarize your issue in one sentence (what goes wrong, what did you
expect to happen).
2. Steps to reproduce: How can we reproduce the issue?
3. Relevant logs and/or screenshots: Please use code blocks (\`\`\`) to format console
output, logs, and code as it's very hard to read otherwise. Also, if your copied
text contains `#` tags or other *Markdown* symbols, please use code blocks
(\`\`\`) or inline code blocks (\`).

Any issue details that might not be obvious to other users should be added to
issue description.

### 2. Issue labels

Every issue *must* also be marked with labels that:
- explains type of issue (`bug`, `feature`, `improvement`);
- explain issue priority (`critical`, `high`, `medium`, `low`).

Other fields like *Assign to* and *Milestone* can be skipped when reporting an issue.

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
