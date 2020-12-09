class RapTopicLevelController < ApplicationController

    before_action only: [:show]

    # GET /rap_topic_level
    def index
        @topics = RapTopicLevel.all
        render json: @topics
    end

    # GET /rap_topic_level/:rap_program_level_id
    def show
        @topics = RapTopicLevel.where("rap_program_level_id = ?", params[:rap_program_level_id])
        render json: @topics
    end

end
