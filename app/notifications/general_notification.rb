# frozen_string_literal: true

class GeneralNotification < BaseNotification
  def message
    params[:message]
  end

  def title
    params[:title]
  end

  def subtype
    params[:type]
  end

  def subject
    params[:subject]
  end
end
