# frozen_string_literal: true

module RepositoriesDatatableHelper
  include InputSanitizeHelper

  def prepare_repositories_datatable(repositories, team, _config)
    result = []
    repositories = repositories.includes(:repository_rows, :team, :created_by, :archived_by)
    repositories.each do |repository|
      result.push(
        'DT_RowId': repository.id,
        '1': escape_input(repository.name),
        '2': repository.repository_rows.size,
        '3': repository.shared_with?(team),
        '4': escape_input(repository.team.name),
        '5': {
          display: I18n.l(repository.created_at, format: :full),
          sort: repository.created_at.to_i
        },
        '6': escape_input(repository.created_by.full_name),
        '7': {
          display: (I18n.l(repository.archived_on, format: :full) if repository.archived_on),
          sort: repository.archived_on&.to_i
        },
        '8': escape_input(repository.archived_by&.full_name),
        'repositoryUrl': repository_path(repository),
        'DT_RowAttr': {
          'data-delete-modal-url': team_repository_destroy_modal_path(team, repository_id: repository),
          'data-copy-modal-url': team_repository_copy_modal_path(team, repository_id: repository),
          'data-rename-modal-url': team_repository_rename_modal_path(team, repository_id: repository)
        }
      )
    end
    result
  end
end
