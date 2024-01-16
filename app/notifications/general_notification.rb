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
    subject_class = params[:subject_class].constantize
    subject_class.find(params[:subject_id])
  rescue NameError, ActiveRecord::RecordNotFound
    NonExistantRecord.new(params[:subject_name])
  end
end
