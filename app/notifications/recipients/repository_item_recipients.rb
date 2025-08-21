# frozen_string_literal: true

class Recipients::RepositoryItemRecipients
  def initialize(params)
    @repository_row_id = params[:repository_row_id]
  end

  def recipients
    repository = RepositoryRow.find(@repository_row_id).repository
    repository.users_with_permission(RepositoryPermissions::READ, repository.team)
  end
end
