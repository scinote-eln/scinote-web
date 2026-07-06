# frozen_string_literal: true

class MyModuleAnalyticalReportsController < ApplicationController
  include ApplicationHelper
  include Breadcrumbs
  include TeamsHelper

  before_action :load_my_module
  before_action :check_my_module_view_permissions
  before_action :load_attachment, only: %i(download destroy)
  before_action :set_breadcrumbs_items, only: %i(index)
  before_action :set_navigator, only: %i(index)
  before_action :set_inline_name_editing, only: %i(index)

  def index
    respond_to do |format|
      format.json do
        render json: {
          templates: @my_module.protocol.odt_template_files.map do |file|
            { name: file.blob.custom_metadata[:template_name] }
          end
        }
      end

      format.html do
        render(:index, formats: :html)
      end
    end
  end

  def generated_reports
    # TODO expected values per file: id, name, created_at
    render json: {}
  end

  def destroy
    # TODO
  end

  def download
     # TODO
  end

  private

  def load_my_module
    @my_module = MyModule.find_by(id: params[:my_module_id])

    render_404 unless @my_module

    current_team_switch(@my_module.experiment.project.team) if current_team != @my_module.experiment.project.team
  end

  def load_attachment
    # TODO
  end

  def check_my_module_view_permissions
    render_403 unless can_read_my_module?(@my_module)
  end

  def set_navigator
    @navigator = {
      url: tree_navigator_my_module_path(@my_module),
      archived: @my_module.archived_branch?,
      id: @my_module.code
    }
  end

  def set_inline_name_editing
    return unless can_manage_my_module?(@my_module)

    @inline_editable_title_config = {
      name: 'title',
      params_group: 'my_module',
      item_id: @my_module.id,
      field_to_udpate: 'name',
      path_to_update: my_module_path(@my_module)
    }
  end
end
