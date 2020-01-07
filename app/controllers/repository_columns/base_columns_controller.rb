# frozen_string_literal: true

module RepositoryColumns
  class BaseColumnsController < ApplicationController
    include InputSanitizeHelper
    before_action :load_repository

    private

    def load_repository
      @repository = Repository.accessible_by_teams(current_team).find_by(id: params[:repository_id])
      render_404 unless @repository
    end

    def load_column
      @repository_column = @repository.repository_columns.find_by(id: params[:id])
      render_404 unless @repository_column
    end

    def check_create_permissions
      render_403 unless can_create_repository_columns?(@repository)
    end

    def check_manage_permissions
      render_403 unless can_manage_repository_column?(@repository_column)
    end
  end
end
