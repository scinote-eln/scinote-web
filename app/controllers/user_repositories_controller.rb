class UserRepositoriesController < ApplicationController
  before_action :load_vars

  def save_table_state
    service = RepositoryTableStateService.new(current_user, @repository)
    service.update_state(params.require(:state).permit!.to_h)
    render json: {
      status: :ok
    }
  end

  def load_table_state
    service = RepositoryTableStateService.new(current_user, @repository)
    state = service.load_state.state
    if state
      render json: {
        state: state
      }
    end
  end

  private

  def load_vars
    @repository = RepositoryBase.find_by(id: params[:repository_id])
    render_403 if @repository.nil? || !can_read_repository?(@repository)
  end
end
