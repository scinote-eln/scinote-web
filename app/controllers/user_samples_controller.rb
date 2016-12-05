class UserSamplesController < ApplicationController
  def save_samples_table_status
    samples_table = SamplesTable.where(user: @current_user,
                                       organization: params[:org])
    if samples_table
      samples_table.first.update(status: params[:state])
    else
      SamplesTable.create(user: @current_user,
                          organization: params[:org],
                          status: params[:state])
    end
    respond_to do |format|
      format.json do
        render json: {
          status: :ok
        }
      end
    end
  end

  def load_samples_table_status
    @samples_table_state = SamplesTable.find_status(current_user,
                                                    current_organization).first
    respond_to do |format|
      if @samples_table_state
        format.json do
          render json: {
            state: @samples_table_state
          }
        end
      end
    end
  end
end
