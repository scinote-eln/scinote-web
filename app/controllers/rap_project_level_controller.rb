class RapProjectLevelController < ApplicationController

    before_action only: [:show]

    # GET /rap_project_level
    def index
        @projects = RapProjectLevel.all
        render json: @projects
    end

    # GET /rap_project_level/:rap_topic_level_id
    def show
        @projects = RapProjectLevel.where(" rap_topic_level_id = ?", params[:rap_topic_level_id])
        render json: @projects
    end

end
