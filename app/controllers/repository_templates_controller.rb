# frozen_string_literal: true

class RepositoryTemplatesController < ApplicationController
  before_action :check_read_permissions
  before_action :load_repository_template, only: :list_repository_columns

  def index
    repository_templates = current_team.repository_templates.order(:id)
    render json: {
      data: repository_templates.map { |repository_template| [repository_template.id, repository_template.name] }
    }
  end

  def list_repository_columns
    render json: {
      name: @repository_template.name,
      columns: @repository_template.column_definitions&.map do |column|
        [column.dig('params', 'name'), I18n.t("libraries.manange_modal_column.select.#{RepositoryColumn.data_types.key(column['column_type']).underscore}")]
      end
    }
  end

  private

  def load_repository_template
    @repository_template = current_team.repository_templates.find_by(id: params[:id])
    render_404 unless @repository_template
  end

  def check_read_permissions
    render_403 unless can_create_repositories?(current_team)
  end
end
