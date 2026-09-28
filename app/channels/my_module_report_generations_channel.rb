# frozen_string_literal: true

class MyModuleReportGenerationsChannel < ApplicationCable::Channel
  def subscribed
    my_module = MyModule.find(params[:my_module_id])
    stream_for my_module
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
