# frozen_string_literal: true

class ExperimentReportGenerationsChannel < ApplicationCable::Channel
  def subscribed
    experiment = Experiment.find(params[:experiment_id])
    stream_for experiment
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
