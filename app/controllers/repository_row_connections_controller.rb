# frozen_string_literal: true

class RepositoryRowConnectionsController < ApplicationController
  before_action :load_repository, except: %i(repositories)
  before_action :load_create_vars, only: :create
  before_action :check_read_permissions, except: :repositories
  before_action :load_repository_row, except: %i(repositories repository_rows)
  before_action :check_manage_permissions, only: %i(create destroy)

  def index
    parents = @repository_row.parent_connections
                             .joins('INNER JOIN repository_rows ON
                                    repository_rows.id = repository_row_connections.parent_id')
                             .select(:id, 'repository_rows.id AS repository_row_id',
                                     'repository_rows.name AS repository_row_name')
                             .map do |row|
                               {
                                 id: row.id,
                                 name: row.repository_row_name,
                                 code: "#{RepositoryRow::ID_PREFIX}#{row.repository_row_id}"
                               }
                             end
    children = @repository_row.child_connections
                              .joins('INNER JOIN repository_rows ON
                                     repository_rows.id = repository_row_connections.child_id')
                              .select(:id, 'repository_rows.id AS repository_row_id',
                                      'repository_rows.name AS repository_row_name')
                              .map do |row|
                                {
                                  id: row.id,
                                  name: row.repository_row_name,
                                  code: "#{RepositoryRow::ID_PREFIX}#{row.repository_row_id}"
                                }
                              end
    render json: { parents: parents, children: children }
  end

  def create
    # Filter existing relations from params
    relation_ids = connection_params[:relation_ids].map(&:to_i) -
                   @repository_row.public_send("#{@relation}_connections").pluck("#{@relation}_id") -
                   [@repository_row.id]
    RepositoryRowConnection.transaction do
      @connection_repository.repository_rows.where(id: relation_ids).find_each do |row|
        attributes = {
          created_by: current_user,
          last_modified_by: current_user,
          "#{@relation}": row
        }
        @repository_row.public_send("#{@relation}_connections").build attributes

        log_activity(:inventory_item_relationships_linked,
                     @repository_row.repository,
                     { inventory_item: @repository_row.name,
                       linked_inventory_item: row.name,
                       relationship_type: @relation })
      end
      @repository_row.save!
    end

    if @repository_row.valid?
      relations = @repository_row.public_send("#{@relation}_repository_rows")
                                 .preload(:repository)
                                 .map do |row|
                                   {
                                     name: row.name,
                                     code: row.code,
                                     path: repository_repository_row_path(row.repository, row),
                                     repository_name: row.repository.name,
                                     repository_path: repository_path(row.repository)
                                   }
                                 end
      render json: {
        "#{@relation.pluralize}": relations
      }
    else
      render json: { errors: @repository_row.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    RepositoryRowConnection.transaction do
      connection = @repository_row.parent_connections.or(@repository_row.child_connections).find(params[:id])
      unlinked_item = connection.parent?(@repository_row) ? connection.child : connection.parent

      log_activity(:inventory_item_relationships_unlinked,
                   @repository_row.repository,
                   { inventory_item: @repository_row.name,
                     unlinked_inventory_item: unlinked_item.name })

      connection.destroy!
      head :no_content
    rescue StandardError
      head :unprocessable_entity
    end
  end

  def repositories
    repositories = Repository.accessible_by_teams(current_team)
                             .search_by_name_and_id(current_user, current_user.teams, params[:query])
                             .order(name: :asc)
                             .page(params[:page] || 1)
                             .per(Constants::SEARCH_LIMIT)
    render json: {
      data: repositories.select(:id, :name)
                        .map { |repository| { id: repository.id, name: repository.name } },
      next_page: repositories.next_page
    }
  end

  def repository_rows
    repository_rows = @repository.repository_rows
                                 .search_by_name_and_id(current_user, current_user.teams, params[:query])
                                 .order(name: :asc)
                                 .page(params[:page] || 1)
                                 .per(Constants::SEARCH_LIMIT)
    render json: {
      data: repository_rows.select(:id, :name)
                           .map { |repository| { id: repository.id, name: repository.name } },
      next_page: repository_rows.next_page
    }
  end

  private

  def load_create_vars
    @relation = 'parent' if connection_params[:relation] == 'parent'
    @relation = 'child' if connection_params[:relation] == 'child'
    return render_422(t('.invalid_params')) unless @relation

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
