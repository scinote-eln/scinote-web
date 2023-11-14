# frozen_string_literal: true

class RepositoryRowConnectionsController < ApplicationController
  before_action :load_repository, except: %i(repositories create)
  before_action :load_create_vars, only: :create
  before_action :check_read_permissions, except: :repositories
  before_action :load_repository_row, except: %i(repositories repository_rows)
  before_action :check_manage_permissions, except: %i(repositories repository_rows index)

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
    connection_params[:relation_ids]
    RepositoryRowConnection.transaction do
      @repository.repository_rows.where(id: connection_params[:relation_ids]).find_each do |row|
        attributes = {
          created_by: current_user,
          last_modified_by: current_user,
          "#{@relation}": row
        }
        @repository_row.public_send("#{@relation}_connections").build attributes
      end
      @repository_row.save!
    end
    if @repository_row.valid?
      relations = @repository_row.public_send("#{@relation}_repository_rows")
                                 .select(:id, :name)
                                 .map do |row|
                                   { id: row.id, name: row.name, code: "#{RepositoryRow::ID_PREFIX}#{row.id}" }
                                 end
      render json: {
        "#{@relation.pluralize}": relations
      }
    else
      render json: { errors: @repository_row.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    connection = @repository_row.parent_connections.or(@repository_row.child_connections).find(params[:id])
    connection.destroy
    head :no_content
  end

  def repositories
    repositories = Repository.accessible_by_teams(current_team)
                             .search_by_name_and_id(current_user, current_user.teams, params[:query])
                             .page(params[:page] || 1)
                             .per(Constants::SEARCH_LIMIT)
    render json: repositories.select(:id, :name).map { |repository| { id: repository.id, name: repository.name } }
  end

  def repository_rows
    repository_rows = @repository.repository_rows
                                 .search_by_name_and_id(current_user, current_user.teams, params[:query])
                                 .page(params[:page] || 1)
                                 .per(Constants::SEARCH_LIMIT)
    render json: repository_rows.select(:id, :name).map { |repository| { id: repository.id, name: repository.name } }
  end

  private

  def load_create_vars
    @relation = 'parent' if connection_params[:relation] == 'parent'
    @relation = 'child' if connection_params[:relation] == 'child'
    return render_422(t('.invalid_params')) unless @relation

    @repository = Repository.accessible_by_teams(current_team)
                            .active
                            .find_by(id: connection_params[:repository_id])
    return render_404 unless @repository
  end

  def load_repository
    @repository = Repository.accessible_by_teams(current_team).active.find_by(id: params[:repository_id])
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

  def connection_params
    params.require(:repository_row_connection).permit(:repository_id, :relation, relation_ids: [])
  end
end
