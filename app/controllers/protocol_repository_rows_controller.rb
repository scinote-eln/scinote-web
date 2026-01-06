# frozen_string_literal: true

class ProtocolRepositoryRowsController < ApplicationController
  before_action :load_protocol
  before_action :check_read_permissions, except: %i(create batch_destroy)
  before_action :check_manage_permissions, only: %i(create batch_destroy)
  before_action :set_inline_name_editing, only: :index
  before_action :set_breadcrumbs_items, only: :index

  def index
    respond_to do |format|
      format.json do
        rows = Lists::ProtocolRepositoryRowsService.new(@protocol.protocol_repository_rows.preload(repository_row: :repository), params).call
        render json: rows, each_serializer: Lists::ProtocolRepositoryRowSerializer, user: current_user, meta: pagination_dict(rows)
      end
      format.html do
        @active_tab = :repository_rows
      end
    end
  end

  def create
    @protocol.transaction do
      RepositoryRow.readable_by_user(current_user, current_user.teams)
                   .where.not(id: @protocol.protocol_repository_rows.where.not(repository_row_id: nil).select(:repository_row_id))
                   .where(id: params[:repository_row_ids]).each do |repository_row|
        @protocol_repository_row = @protocol.protocol_repository_rows.create!(repository_row: repository_row)
        log_activitiy(:protocol_repository_item_added, @protocol_repository_row)
      end
      render json: {}
    end
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error e.message
    render json: { errors: e.message }, status: :unprocessable_entity
  end

  def batch_destroy
    @protocol.transaction do
      @protocol.protocol_repository_rows.where(id: params[:row_ids]).find_each do |protocol_repository_row|
        log_activitiy(:protocol_repository_item_removed, protocol_repository_row)
        protocol_repository_row.destroy!
      end
      head :no_content
    end
  rescue StandardError => e
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

  def actions_toolbar
    render json: {
      actions:
        Toolbars::ProtocolRepositoryRowsService.new(
          current_user,
          @protocol,
          row_ids: JSON.parse(params[:items]).pluck('id')
        ).actions
    }
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

  def log_activitiy(type_of, protocol_repository_row)
    protocol = protocol_repository_row.protocol
    repository_row = protocol_repository_row.repository_row
    message_items = {
      protocol: protocol.id,
      repository_row: repository_row.id,
      repository: repository_row.repository.id
    }

    Activities::CreateActivityService.call(
      activity_type: type_of,
      owner: current_user,
      subject: protocol,
      team: protocol.team,
      project: nil,
      message_items: message_items
    )
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
