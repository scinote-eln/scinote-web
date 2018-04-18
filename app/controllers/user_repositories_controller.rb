class UserRepositoriesController < ApplicationController
  before_action :load_vars

  def save_table_state
    RepositoryTableState.update_state(current_user, @repository, params[:state])
    respond_to do |format|
      format.json do
        render json: {
          status: :ok
        }
      end
    end
  end

  def load_table_state
    table_state = RepositoryTableState.load_state(current_user,
                                                  @repository)
                                      .state
    respond_to do |format|
      if table_state
        format.json do
          render json: {
            state: table_state
          }
        end
      end
    end
  end

  private

  def load_vars
    @repository = Repository.find_by_id(params[:repository_id])
    render_403 if @repository.nil? || !can_read_team?(@repository.team)
  end
end
