# frozen_string_literal: true

module RepositoriesDatatableHelper
  include InputSanitizeHelper

  def prepare_repositories_datatable(repositories, team, _config)
    result = []
    repositories = repositories.includes(:repository_rows, :team, :created_by)
    repositories.each do |repository|
      result.push(
        'DT_RepositoryId': repository.id,
        '1': escape_input(repository.name),
        '2': repository.repository_rows.size,
        '3': repository.shared_with?(team),
        '4': escape_input(repository.team.name),
        '5': I18n.l(repository.created_at, format: :full),
        '6': escape_input(repository.created_by.full_name),
        'repositoryUrl': repository_path(repository)
      )
    end
    result
  end
end
