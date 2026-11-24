# Design system

The design elements page is SciNote's catalogue of built UI components. It runs at `/qa_tools/design_elements` in development, or whenever `ENABLE_QA_TOOLS=true`. If a component is on the page, use it. If it isn't, add it here before using it anywhere else.

Every section has an anchor, so a single component can be linked, e.g. `/qa_tools/design_elements#toast`. The sidebar on the left lists them all and stays visible while you scroll.

## Rules

- Take colours from the `sn-*` Tailwind tokens in `config/tailwind.config.js`. A colour with no token is a design question for the ticket; it doesn't become a new hex value.
- Use the SN icon font: `<i class="sn-icon sn-icon-<name>"></i>`.
- Put copy in `config/locales/`, and give every interactive element a `data-e2e` attribute.
- Each component's partial shows every variant and state it supports, using fixed demo content so the page looks the same on every load.

## Adding a component

Every contribution has a Jira ticket and a PR against `develop`, like any other change.

**CSS-class component** (button, tag, toast, toggle…):

1. Define the class in `app/assets/stylesheets/tailwind/<name>.css` with `@apply` and `sn-*` tokens, and import it in `app/assets/stylesheets/application.tailwind.css`.
2. Add `app/views/qa_tools/design_elements/_<name>.html.erb` showing the variant × state matrix, under an `<h1>` with the component name.
3. Register it: add one entry to `SECTIONS` in `app/controllers/qa_tools/design_elements_controller.rb`, under its family.

**Vue component** (input, select, modal, table…):

1. Add the component to `app/javascript/vue/shared/<name>.vue`.
2. Add a demo pack, `app/javascript/packs/vue/design_system/<name>.js`, that registers the component and mounts it with `mountWithTurbolinks`.
3. Add `vue_design_system_<name>` to `entryList` in `config/webpack/webpack.config.js`.
4. Add the partial with a mount element and `javascript_include_tag 'vue_design_system_<name>'`.
5. Register it in `SECTIONS`, as above.

**Section ids:** the `id` in `SECTIONS` is the component name, singular and kebab-case (`input-field`, `date-time-picker`). It must not be the same as an element id inside any partial, such as a Vue mount element (`#table`, `#selects`); two equal ids break the mount.

**Changing an existing component:** list its usages (`grep -rn "<class-or-component>" app addons`) in the PR, and check each affected screen.

## Before opening the PR

- The page section matches the design at 100% zoom, in every state.
- The component works with the keyboard alone, and focus is visible.
- The diff contains no raw hex colours.
- `yarn eslint`, `scss-lint` and `bin/rubocop` pass.
- The PR description includes before/after screenshots of the page section.
