# frozen_string_literal: true

class ProtocolRepositoryRowsController < ApplicationController
  before_action :load_protocol
  before_action :load_protocol_repository_row, only: %i(destroy)
  before_action :check_read_permissions, except: %i(create destroy)
  before_action :check_manage_permissions, only: %i(create destroy)

  def index
    respond_to do |format|
      format.json do
        @protocol_repository_rows = @protocol.protocol_repository_rows.preload(repository_row: :repository)
      end
      format.html do
        @active_tab = :repository_rows
      end
    end
  end

  def create
    @protocol.transaction do
      @protocol_repository_row = @protocol.protocol_repository_rows.create!
      render json: {}
    end
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error e.message
    render json: { errors: @protocol_repository_row.errors.full_messages }, status: :unprocessable_entity
  end

  def destroy
    @protocol.transaction do
      @protocol_repository_row.destroy!
      head :no_content
    end
  rescue StandardError
    Rails.logger.error e.message
    head :unprocessable_entity
  end

  def repositories
    repositories = Repository.readable_by_user(current_user)
                             .search_by_name_and_id(current_user, current_user.teams, params[:query])
                             .order(name: :asc)
                             .page(params[:page] || 1)
                             .per(Constants::SEARCH_LIMIT)
    render json: {
      data: repositories.select(:id, :name, :archived)
                        .map { |repository| [repository.id, repository.name_with_label] },
      paginated: true,
      next_page: repositories.next_page
    }
  end

  def repository_rows
    selected_repository = Repository.readable_by_user(current_user).find(params[:selected_repository_id])

    repository_rows = selected_repository.repository_rows
                                         .where.not(id: @protocol.protocol_repository_rows.select(:repository_row_id))
                                         .search_by_name_and_id(current_user, current_user.teams, params[:query])
                                         .order(name: :asc)
                                         .page(params[:page] || 1)
                                         .per(Constants::SEARCH_LIMIT)
    render json: {
      data: repository_rows.select(:id, :name, :archived, :repository_id)
                           .map { |row| [row.id, row.name_with_label] },
      paginated: true,
      next_page: repository_rows.next_page
    }
  end

  private

  def load_protocol
    @protocol = current_team.protocols.readable_by_user(current_user).find_by(id: params[:protocol_id])
    render_404 unless @protocol
  end

  def load_protocol_repository_row
    @protocol_repository_row = @protocol.protocol_repository_rows.find_by(id: params[:id])
    render_404 unless @protocol_repository_row
  end

  def check_read_permissions
    render_403 unless can_read_protocol_in_repository?(@protocol)
  end

  def check_manage_permissions
    render_403 unless can_manage_protocol_draft_in_repository?(@protocol)
  end

  def protocol_repository_row_params
    params.require(:protocol_repository_row).permit(:repository_row_id)
  end
end
