# frozen_string_literal: true

class DeliveryNotification < BaseNotification
  def self.subtype
    :delivery
  end

  def message
    params[:message]
  end

  def title
    params[:title]
  end

  def subject
    return unless params[:subject_id] && params[:subject_class]

    params[:subject_class].constantize.find(params[:subject_id])
  rescue ActiveRecord::RecordNotFound
    NonExistantRecord.new(params[:subject_name])
  end
end
