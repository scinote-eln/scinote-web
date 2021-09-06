# frozen_string_literal: true

class ActiveJobsController < ApplicationController
  def status
    render json: { status: ApplicationJob.status(params[:id]) }
  end
end
