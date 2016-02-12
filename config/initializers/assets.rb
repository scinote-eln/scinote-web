# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = '1.0'

# Add additional assets to the asset load path
# Rails.application.config.assets.paths << Emoji.images_path

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in app/assets folder are already added.
Rails.application.config.assets.precompile += %w( underscore.js )
Rails.application.config.assets.precompile += %w( jsPlumb-2.0.4-min.js )
Rails.application.config.assets.precompile += %w( jsnetworkx.js )
Rails.application.config.assets.precompile += %w( handsontable.full.min.js )
Rails.application.config.assets.precompile += %w( users/settings/preferences.js )
Rails.application.config.assets.precompile += %w( users/settings/organizations.js )
Rails.application.config.assets.precompile += %w( users/settings/organizations/add_user_modal.js )
Rails.application.config.assets.precompile += %w( users/settings/organization.js )
Rails.application.config.assets.precompile += %w( my_modules/activities.js )
Rails.application.config.assets.precompile += %w( my_modules/steps.js )
Rails.application.config.assets.precompile += %w( my_modules/results.js )
Rails.application.config.assets.precompile += %w( results/result_tables.js )
Rails.application.config.assets.precompile += %w( results/result_assets.js )
Rails.application.config.assets.precompile += %w( results/result_texts.js )
Rails.application.config.assets.precompile += %w( users/registrations/edit.js )
Rails.application.config.assets.precompile += %w( jquery-ui/draggable.js )
Rails.application.config.assets.precompile += %w( jquery-ui/droppable.js )
Rails.application.config.assets.precompile += %w( jquery.ui.touch-punch.min.js )
Rails.application.config.assets.precompile += %w( bootstrap-colorselector.js )
Rails.application.config.assets.precompile += %w( eventPause-min.js )
Rails.application.config.assets.precompile += %w( sidebar.js )
Rails.application.config.assets.precompile += %w( samples/samples.js )
Rails.application.config.assets.precompile += %w( samples/sample_datatable.js )
Rails.application.config.assets.precompile += %w( projects/index.js )
Rails.application.config.assets.precompile += %w( samples/samples_importer.js )
Rails.application.config.assets.precompile += %w( projects/canvas.js )
Rails.application.config.assets.precompile += %w( reports/index.js )
Rails.application.config.assets.precompile += %w( reports/new_by_module.js )
Rails.application.config.assets.precompile += %w( datatables.js )
Rails.application.config.assets.precompile += %w( search/index.js )
Rails.application.config.assets.precompile += %w( navigation.js )
Rails.application.config.assets.precompile += %w( datatables.css )
Rails.application.config.assets.precompile += %w( my_modules.js )
Rails.application.config.assets.precompile += %w( direct-upload.js )
Rails.application.config.assets.precompile += %w( canvas-to-blob.min.js )
Rails.application.config.assets.precompile += %w( Sortable.min.js )
Rails.application.config.assets.precompile += %w( reports_pdf.css )
