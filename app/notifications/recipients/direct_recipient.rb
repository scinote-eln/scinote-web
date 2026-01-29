# frozen_string_literal: true

class Recipients::DirectRecipient
  def initialize(params)
    @params = params
  end

  def recipients
    [(@params[:user] || User.find_by(id: @params[:user_id]))].compact
  end
end
