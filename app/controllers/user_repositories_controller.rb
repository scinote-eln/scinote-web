class UserRepositoriesController < ApplicationController
  before_action :load_vars

  def save_table_state
    service = RepositoryTableStateService.new(current_user, @repository)
    service.update_state(params.require(:state).permit!.to_h)
    respond_to do |format|
      format.json do
        render json: {
          status: :ok
        }
      end
    end
  end

  def load_table_state
    service = RepositoryTableStateService.new(current_user, @repository)
    state = service.load_state.state
    respond_to do |format|
      if state
        format.json do
          render json: {
            state: state
          }
        end
      end
    end
  end

  private

  def load_vars
    @repository = Repository.find_by_id(params[:repository_id])
    render_403 if @repository.nil? || !can_read_repository?(@repository)
  end
end
