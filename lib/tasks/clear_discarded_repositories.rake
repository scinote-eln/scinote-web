namespace :clear_discarded_repositories do
  desc 'Removes all discarded repositories'
  task run: :environment do
    Repository.with_discarded.discarded.destroy_all
  end
end
