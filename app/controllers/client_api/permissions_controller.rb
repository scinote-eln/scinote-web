module ClientApi
  class PermissionsController < ApplicationController
    def state
      respond_to do |format|
        format.json do
          render json: {
            can_update_team?: false,
            can_read_team?: true
          }, status: :ok
        end
      end
    end
  end
end
# holder = Canaid::PermissionsHolder.instance
# https://github.com/biosistemika/canaid/blob/master/lib/canaid/helpers/permissions_helper.rb
