# frozen_string_literal: true

class EditingFlagsChannel < ApplicationCable::Channel
  def subscribed
    subject = find_subject
    return reject unless subject

    stream_for subject
  end

  def unsubscribed
  end

  private

  def find_subject
    klass = params[:subject_type].to_s.safe_constantize
    return unless klass && klass < ActiveRecord::Base

    klass.find_by(id: params[:subject_id])
  end
end
