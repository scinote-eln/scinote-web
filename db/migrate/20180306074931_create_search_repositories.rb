class CreateSearchRepositories < ActiveRecord::Migration[5.1]
  def change
    create_view :search_repositories
  end
end
