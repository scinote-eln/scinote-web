class UserSamplesController < ApplicationController
  def save_samples_table_status
    samples_table = SamplesTable.where(user: @current_user,
                                       team: params[:team])
                                .order(:id)
                                .first
    if samples_table
      samples_table.update(status: params[:state])
    else
      SamplesTable.create(user: @current_user,
                          team: params[:team],
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
    samples_table_state = SamplesTable.find_status(current_user,
                                                   current_team)
    if samples_table_state.blank?
      st = SamplesTable.new(user: current_user, team: current_team)
      st.save
      samples_table_state = st.status
    end

    respond_to do |format|
      if samples_table_state
        format.json do
          render json: {
            state: samples_table_state
          }
        end
      end
    end
  end
end
