# frozen_string_literal: true

class Recipients::RepositoryItemRecipients
  def initialize(params)
    @repository_row_id = params[:repository_row_id]
  end

  def recipients
    repository_row = RepositoryRow.find(@repository_row_id)
    repository_row.repository.team.users
  end
end
