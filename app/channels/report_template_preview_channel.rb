# frozen_string_literal: true

class ReportTemplatePreviewChannel < ApplicationCable::Channel
  include Canaid::Helpers::PermissionsHelper

  def subscribed
    report_template = ReportTemplate.find_by(id: params[:report_template_id])
    return reject unless report_template && can_read_report_template?(report_template)

    stream_for report_template

    transmit({ status: report_template.preview_status })
  end

  def unsubscribed
    stop_all_streams
  end

  private

  def can_read_report_template?(report_template)
    protocol = report_template.subject

    can_read_protocol_in_module?(current_user, protocol) || can_read_protocol_in_repository?(current_user, protocol)
  end
end
