# frozen_string_literal: true

class Recipients::DirectRecipient
  def initialize(params)
    @params = params
  end

  def recipients
    [@params[:user]]
  end
end
