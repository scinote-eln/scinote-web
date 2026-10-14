# frozen_string_literal: true

class MyModuleStatusChannel < ApplicationCable::Channel
  include Canaid::Helpers::PermissionsHelper

  def subscribed
    my_module = load_my_module

    return reject unless my_module && can_read_my_module?(current_user, my_module)

    stream_for my_module
  end

  def unsubscribed
    stop_all_streams
  end

  def sync
    my_module = load_my_module

    transmit(my_module.status_broadcast_payload) if my_module
  end

  private

  def load_my_module
    MyModule.find_by(id: params[:my_module_id])
  end
end
