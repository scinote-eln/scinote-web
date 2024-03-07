# frozen_string_literal: true

class RepositoryRowConnectionsController < ApplicationController
  before_action :load_repository, except: :repositories
  before_action :load_create_vars, only: :create
  before_action :check_read_permissions, except: :repositories
  before_action :load_repository_row, except: :repositories
  before_action :check_manage_permissions, only: %i(create destroy)

  def create
    RepositoryRowConnection.transaction do
      @connection_repository.repository_rows
                            .where(id: connection_params[:relation_ids])
                            .where.not(id: @repository_row.id)
                            .where.not(
                              id: if @relation_type == 'parent'
                                    @repository_row.parent_connections.select(:parent_id)
                                  else
                                    @repository_row.child_connections.select(:child_id)
                                  end
                            )
                            .find_each do |linked_repository_row|
        build_connection(linked_repository_row)
        log_activity(:inventory_item_relationships_linked,
                     @repository_row.repository,
                     { repository_row: @repository_row.id,
                       repository_row_linked: linked_repository_row.id,
                       relationship_type: @relation_type == 'parent' ? 'parent' : 'child' })
      end

      @repository_row.save!

      relation_key = @relation_type == 'parent' ? :parents : :children
      render json: { relation_key => connected_rows_by_relation_type }
    end
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error e.message
    render json: { errors: @repository_row.errors.full_messages }, status: :unprocessable_entity
  end

  def destroy
    RepositoryRowConnection.transaction do
      connection = @repository_row.parent_connections.or(@repository_row.child_connections).find(params[:id])
      unlinked_repository_row = connection.parent?(@repository_row) ? connection.child : connection.parent

      log_activity(:inventory_item_relationships_unlinked,
                   @repository_row.repository,
                   { repository_row: @repository_row.id,
                     repository_row_unlinked: unlinked_repository_row.id })

      connection.destroy!
      head :no_content
    end
  rescue StandardError
    head :unprocessable_entity
  end

  def repositories
    repositories = Repository.accessible_by_teams(current_team)
                             .search_by_name_and_id(current_user, current_user.teams, params[:query])
                             .order(name: :asc)
                             .page(params[:page] || 1)
                             .per(Constants::SEARCH_LIMIT)
    render json: {
      data: repositories.select(:id, :name, :archived)
                        .map { |repository| { id: repository.id, name: repository.name_with_label } },
      next_page: repositories.next_page
    }
  end

  def repository_rows
    selected_repository = Repository.accessible_by_teams(current_team).find(params[:selected_repository_id])

    repository_rows = selected_repository.repository_rows
                                         .where.not(id: @repository_row.id)
                                         .where.not(id: @repository_row.parent_connections.select(:parent_id))
                                         .where.not(id: @repository_row.child_connections.select(:child_id))
                                         .search_by_name_and_id(current_user, current_user.teams, params[:query])
                                         .order(name: :asc)
                                         .page(params[:page] || 1)
                                         .per(Constants::SEARCH_LIMIT)
    render json: {
      data: repository_rows.select(:id, :name, :archived, :repository_id)
                           .map { |row| { id: row.id, name: row.name_with_label } },
      next_page: repository_rows.next_page
    }
  end

  private

  def load_create_vars
    @relation_type = connection_params[:relation] if connection_params[:relation].in?(%w(parent child))

    return render_422(t('.invalid_params')) unless @relation_type

    @connection_repository = Repository.accessible_by_teams(current_team)
                                       .find_by(id: connection_params[:connection_repository_id])
    return render_404 unless @connection_repository
    return render_403 unless can_connect_repository_rows?(@connection_repository)
  end

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

  def check_manage_permissions
    render_403 unless can_connect_repository_rows?(@repository)
  end

  def connection_params
    params.require(:repository_row_connection).permit(:connection_repository_id, :relation, relation_ids: [])
  end

  def build_connection(linked_repository_row)
    connection_params = {
      created_by: current_user,
      last_modified_by: current_user
    }

    if @relation_type == 'parent'
      @repository_row.parent_connections.build(connection_params.merge(parent: linked_repository_row))
    else
      @repository_row.child_connections.build(connection_params.merge(child: linked_repository_row))
    end
  end

  def connected_rows_by_relation_type
    repository_connections = if @relation_type == 'parent'
                               @repository_row.parent_connections
                             else
                               @repository_row.child_connections
                             end

    repository_connections.map do |connection|
      repository_row = @relation_type == 'parent' ? connection.parent : connection.child

      {
        name: repository_row.name_with_label,
        code: repository_row.code,
        path: repository_repository_row_path(repository_row.repository, repository_row),
        repository_name: repository_row.repository.name_with_label,
        repository_path: repository_path(repository_row.repository),
        unlink_path: repository_repository_row_repository_row_connection_path(
          repository_row.repository,
          repository_row,
          connection
        )
      }
    end
  end

  def log_activity(type_of, repository, message_items = {})
    message_items = { repository: repository.id }.merge(message_items)

    Activities::CreateActivityService
      .call(activity_type: type_of,
            owner: current_user,
            subject: repository,
            team: repository.team,
            message_items: message_items)
  end
end
