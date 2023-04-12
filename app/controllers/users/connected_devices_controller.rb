# frozen_string_literal: true

module Users
  class ConnectedDevicesController < ApplicationController
    before_action :check_delete_permissions, only: :destroy

    def destroy
      @connected_device.destroy
    end

    private

    def check_delete_permissions
      @connected_device = ConnectedDevice.for_user(current_user).find_by(id: params[:id])
      render_403 if @connected_device.blank?
    end
  end
end
