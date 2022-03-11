# frozen_string_literal: true

class HiddenRepositoryCellRemindersController < ApplicationController
  before_action :load_repository
  before_action :load_repository_row
  before_action :check_read_permissions

  def create
    hidden_repository_cell_reminder =
      current_user.hidden_repository_cell_reminders.create!(repository_cell_id: params[:repository_cell_id])

    render json: hidden_repository_cell_reminder, status: :ok
  end

  private

  def load_repository
    @repository = Repository.accessible_by_teams(current_team).find_by(id: params[:repository_id])
    render_404 unless @repository
  end

  def load_repository_row
    @repository_row = @repository.repository_rows.find_by(id: params[:repository_row_id])
    render_404 unless @repository_row
  end

  def check_read_permissions
    render_403 unless can_read_repository?(@repository)
  end
end
