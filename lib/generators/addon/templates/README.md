# SciNote addon - `${ADDON_NAME}`

## How to include this addon inside main SciNote application

* Inside `Gemfile`, add the following reference:

```ruby
gem '${FULL_UNDERSCORE_NAME}',
    path: 'addons/${ADDON_NAME}'
```

* Inside `config/routes.rb`, add the following reference:

```ruby
mount ${NAME}::Engine => '/'
```

* If you have any addon-specific JavaScript code, add the following reference inside `app/assets/javascripts/application.js.erb`:

```js
//= require ${FOLDERS_PATH}
```

* If you have any addon-specific CSS code, add the following reference inside `app/assets/stylesheets/application.scss` (starting comment):

```css
 *= require ${FOLDERS_PATH}/application
```

Then, do the following:

1. Run `make docker`,
2. Run `make cli` -> `rake db:migrate`,
3. (optional) setup any addon initializers/settings,
4. Start application (`make run`)!
