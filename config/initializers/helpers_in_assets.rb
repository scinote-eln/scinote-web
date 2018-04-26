# This code will include the listed helpers in all the assets
Rails.application.config.assets.configure do |env|
  env.context_class.class_eval do
    # This is required for repository_datatable.js.erb
    include RepositoryDatatableHelper
  end
end
