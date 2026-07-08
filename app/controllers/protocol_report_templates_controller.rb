# frozen_string_literal: true

class ProtocolReportTemplatesController < ApplicationController
  before_action :load_protocol
  before_action :check_read_permissions, except: :create
  before_action :check_manage_permissions, only: :create
  before_action :set_inline_name_editing, only: :index
  before_action :set_breadcrumbs_items, only: :index

  def index
    respond_to do |format|
      format.json do
        render json: {
          templates: @protocol.report_templates.map do |report_template|
            { name: report_template.name }
          end
        }
      end

      format.html do
        @active_tab = :protocol_report_templates
        render(:index, formats: :html)
      end
    end
  end

  def create
    ActiveRecord::Base.transaction do
      protocol_report_template = ReportTemplate.new(protocol_report_template_params)

      protocol_report_template.subject = @protocol
      protocol_report_template.odt_template_file.attach(params[:file])
      protocol_report_template.save!
    end
  end

  def input_tags
    input_tags = ProtocolReportTemplates::TagService.new(@protocol).call
    render json: input_tags
  end

  private

  def load_protocol
    @protocol = current_team.protocols.readable_by_user(current_user).find_by(id: params[:protocol_id])
    render_404 unless @protocol
  end

  def check_read_permissions
    render_403 unless can_read_protocol_in_repository?(@protocol)
  end

  def check_manage_permissions
    render_403 unless can_manage_protocol_draft_in_repository?(@protocol)
  end

  def protocol_report_template_params
    params.permit(:name)
  end

  def set_breadcrumbs_items
    archived = params[:view_mode] || (@protocol&.archived? && 'archived')

    @breadcrumbs_items = []
    @breadcrumbs_items.push(
      { label: t('breadcrumbs.protocols'), url: protocols_path(view_mode: archived ? 'archived' : nil) }
    )

    if @protocol
      @breadcrumbs_items.push(
        { label: @protocol.name, url: protocol_path(@protocol) }
      )
    end

    @breadcrumbs_items.each do |item|
      item[:label] = "#{t('labels.archived')} #{item[:label]}" if archived
    end
  end

  def set_inline_name_editing
    return unless can_manage_protocol_draft_in_repository?(@protocol)

    @inline_editable_title_config = {
      name: 'title',
      params_group: 'protocol',
      item_id: @protocol.id,
      field_to_udpate: 'name',
      path_to_update: name_protocol_path(@protocol)
    }
  end
end
