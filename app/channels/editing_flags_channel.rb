# frozen_string_literal: true

class EditingFlagsChannel < ApplicationCable::Channel
  include Canaid::Helpers::PermissionsHelper

  def subscribed
    subject = find_subject
    return reject unless subject && can_read_subject?(subject)

    stream_for subject
  end

  def unsubscribed; end

  private

  def find_subject
    return unless EditingFlag::SUBJECT_TYPES.include?(params[:subject_type])

    params[:subject_type].constantize.find_by(id: params[:subject_id])
  end

  def can_read_subject?(subject)
    user = User.find_by(id: current_user.id)
    return false unless user

    user.permission_team = subject.team

    case subject
    when StepText
      protocol = subject.step.protocol
      can_read_protocol_in_module?(user, protocol) || can_read_protocol_in_repository?(user, protocol)
    when ResultText
      can_read_result?(user, subject.result)
    else
      false
    end
  end
end
