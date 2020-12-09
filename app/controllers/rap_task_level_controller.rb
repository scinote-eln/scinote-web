class RapTaskLevelController < ApplicationController

    before_action only: [:show]

    # GET /rap_task_level
    def index
        @tasks = RapTaskLevel.all
        render json: @tasks
    end

    # GET /rap_task_level/:rap_project_level_id
    def show
        @tasks = RapTaskLevel.where(" rap_project_level_id = ?", params[:rap_project_level_id])
        render json: @tasks
    end

end
