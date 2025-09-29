# frozen_string_literal: true

class HiddenRepositoryCellRemindersController < ApplicationController
  before_action :load_repository
  before_action :load_repository_row
  before_action :check_read_permissions
  before_action :check_manage_permissions, only: :create_all

  def create
    hidden_repository_cell_reminder =
      current_user.hidden_repository_cell_reminders.create!(repository_cell_id: params[:repository_cell_id])

    render json: hidden_repository_cell_reminder, status: :ok
  end

  def create_all
    repository_cell_id = params[:repository_cell_id]
    hidden_repository_cell_reminder = current_user.hidden_repository_cell_reminders.create!(repository_cell_id: repository_cell_id)
    @repository_row.repository.users.where.not(id: current_user.id).each do |user|
      next if user.hidden_repository_cell_reminders.find_by(repository_cell_id: repository_cell_id)

      user.hidden_repository_cell_reminders.create!(repository_cell_id: repository_cell_id)
    end

    render json: hidden_repository_cell_reminder, status: :ok
  end

  private

  def load_repository
    @repository = Repository.readable_by_user(current_user).find_by(id: params[:repository_id])
    render_404 unless @repository
  end

  def load_repository_row
    @repository_row = @repository.repository_rows.find_by(id: params[:repository_row_id])
    render_404 unless @repository_row
  end

  def check_read_permissions
    render_403 unless can_read_repository?(@repository)
  end

  def check_manage_permissions
    render_403 unless can_manage_repository_rows?(@repository)
  end
end
