# frozen_string_literal: true

class Recipients::ItemCreatorRecipients
  def initialize(params)
    @params = params
  end

  def recipients
    [RepositoryRow.find(@params[:repository_row_id]).created_by]
  end
end
