# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = '1.0'

# Add additional assets to the asset load path.
# Rails.application.config.assets.paths << Emoji.images_path
# Add Yarn node_modules folder to the asset load path.
Rails.application.config.assets.paths << Rails.root.join('node_modules')

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in the app/assets
# folder are already added.
# Rails.application.config.assets.precompile += %w( admin.js admin.css )

Rails.application.config.assets.precompile += %w(underscore.js)
Rails.application.config.assets.precompile += %w(jsPlumb-2.0.4-min.js)
Rails.application.config.assets.precompile += %w(jsnetworkx.js)
Rails.application.config.assets.precompile += %w(handsontable.full.min.js)
Rails.application.config.assets.precompile += %w(handsontable.full.min.css)
Rails.application.config.assets.precompile +=
  %w(sugar.min.js jquerymy-1.2.14.min.js)
Rails.application.config.assets.precompile += %w(users/settings/list_toggle.js.erb)
Rails.application.config.assets.precompile +=
  %w(users/settings/account/preferences/index.js)
Rails.application.config.assets.precompile += %w(users/settings/teams/index.js)
Rails.application.config.assets.precompile +=
  %w(users/settings/teams/datatable.js)
Rails.application.config.assets.precompile +=
  %w(users/settings/teams/add_user_modal.js)
Rails.application.config.assets.precompile += %w(users/settings/teams/show.js)
Rails.application.config.assets.precompile +=
  %w(users/settings/teams/invite_users_modal.js)
Rails.application.config.assets.precompile += %w(my_modules/activities.js)
Rails.application.config.assets.precompile += %w(my_modules/protocols.js)
Rails.application.config.assets.precompile +=
  %w(my_modules/protocols/protocol_status_bar.js)
Rails.application.config.assets.precompile += %w(my_modules/results.js)
Rails.application.config.assets.precompile += %w(assets/wopi/create_wopi_file.js)
Rails.application.config.assets.precompile += %w(results/result_tables.js)
Rails.application.config.assets.precompile += %w(results/result_assets.js)
Rails.application.config.assets.precompile += %w(results/result_texts.js)
Rails.application.config.assets.precompile += %w(users/registrations/edit.js)
Rails.application.config.assets.precompile += %w(jquery-ui/draggable.js)
Rails.application.config.assets.precompile += %w(jquery-ui/droppable.js)
Rails.application.config.assets.precompile += %w(jquery.ui.touch-punch.min.js)
Rails.application.config.assets.precompile += %w(bootstrap-colorselector.js)
Rails.application.config.assets.precompile += %w(emojione.js)
Rails.application.config.assets.precompile += %w(emojionearea.js)
Rails.application.config.assets.precompile += %w(eventPause-min.js)
Rails.application.config.assets.precompile += %w(sidebar.js)
# Rails.application.config.assets.precompile += %w(samples/samples.js)
# Rails.application.config.assets.precompile += %w(samples/sample_datatable.js)
Rails.application.config.assets.precompile += %w(projects/index.js)
# Rails.application.config.assets.precompile += %w(samples/samples_importer.js)
Rails.application.config.assets.precompile += %w(projects/canvas.js)
Rails.application.config.assets.precompile +=
  %w(experiments/dropdown_actions.js)
Rails.application.config.assets.precompile += %w(reports/new.js)
Rails.application.config.assets.precompile += %w(protocols/index.js)
Rails.application.config.assets.precompile += %w(protocols/external_protocols_tab.js)
Rails.application.config.assets.precompile += %w(protocols/header.js)
Rails.application.config.assets.precompile += %w(protocols/steps.js)
Rails.application.config.assets.precompile += %w(protocols/edit.js)
Rails.application.config.assets.precompile +=
  %w(protocols/import_export/eln_table.js)
Rails.application.config.assets.precompile +=
  %w(protocols/import_export/import.js)
Rails.application.config.assets.precompile +=
  %w(protocols/import_export/export.js)
Rails.application.config.assets.precompile += %w(datatables.js)
Rails.application.config.assets.precompile += %w(search/index.js)
Rails.application.config.assets.precompile += %w(global_activities/side_pane.js)
Rails.application.config.assets.precompile += %w(navigation.js)
Rails.application.config.assets.precompile += %w(secondary_navigation.js)
Rails.application.config.assets.precompile += %w(datatables.css)
Rails.application.config.assets.precompile += %w(my_modules.js)
Rails.application.config.assets.precompile += %w(canvas-to-blob.min.js)
Rails.application.config.assets.precompile += %w(Sortable.min.js)
Rails.application.config.assets.precompile += %w(reports_pdf.css)
Rails.application.config.assets.precompile += %w(jszip.min.js)
Rails.application.config.assets.precompile += %w(comments.js)
Rails.application.config.assets.precompile += %w(projects/show.js)
Rails.application.config.assets.precompile += %w(notifications.js)
Rails.application.config.assets.precompile += %w(system_notifications/index.js)
Rails.application.config.assets.precompile += %w(users/invite_users_modal.js)
# Rails.application.config.assets.precompile += %w(samples/sample_types_groups.js)
Rails.application.config.assets.precompile += %w(highlightjs-github-theme.css)
Rails.application.config.assets.precompile += %w(search.js)
Rails.application.config.assets.precompile += %w(repositories/index.js)
Rails.application.config.assets.precompile += %w(repositories/edit.js)
Rails.application.config.assets.precompile +=
  %w(repositories/repository_datatable.js)
Rails.application.config.assets.precompile +=
  %w(repositories/my_module_repository.js)
Rails.application.config.assets.precompile += %w(activities/index.js)
Rails.application.config.assets.precompile += %w(global_activities/index.js)
Rails.application.config.assets.precompile += %w(repositories/show.js)
Rails.application.config.assets.precompile += %w(sidebar_toggle.js)
Rails.application.config.assets.precompile += %w(reports/reports_datatable.js)
Rails.application.config.assets.precompile += %w(reports/save_pdf_to_inventory.js)

# Libraries needed for Handsontable formulas
Rails.application.config.assets.precompile += %w(lodash.js)
Rails.application.config.assets.precompile += %w(numeral.js)
Rails.application.config.assets.precompile += %w(numeric.js)
Rails.application.config.assets.precompile += %w(md5.js)
Rails.application.config.assets.precompile += %w(jstat.js)
Rails.application.config.assets.precompile += %w(formula.js)
Rails.application.config.assets.precompile += %w(parser.js)
Rails.application.config.assets.precompile += %w(ruleJS.js)
Rails.application.config.assets.precompile += %w(handsontable.formula.js)
Rails.application.config.assets.precompile += %w(handsontable.formula.css)
Rails.application.config.assets.precompile += %w(big.min.js)
