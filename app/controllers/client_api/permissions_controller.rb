module ClientApi
  class PermissionsController < ApplicationController
    before_action :generate_permissions_object, only: :status

    def status
      respond_to do |format|
        format.json do
          render json: @permissions, status: :ok
        end
      end
    end

    private

    def generate_permissions_object
      sanitize_permissions!
      @permissions = {}
      if @resource
        @required_permissions.collect do |permission|
          @permissions.merge!("#{permission}?" => @holder.eval(permission,
                                                               current_user,
                                                               @resource))
        end
      else
        @required_permissions.collect do |permission|
          @permissions.merge!(
            "#{permission}?" => @holder.eval_generic(permission, current_user)
          )
        end
      end
    end

    def sanitize_permissions!
      @required_permissions = params.fetch(:parsePermission) do
        :permissions_array_missing
      end
      @holder = Canaid::PermissionsHolder.instance
      @required_permissions.each do |permission|
        next if @holder.has_permission?(permission)
        # this error should happen only in development
        raise ArgumentError, "Method #{permission} has no related " \
                             "permission registered."
      end
      # sanitize resource, this error should happen only in development
      raise ArgumentError,
            "Resource #{@resource} does not exists" unless resource_valid?
    end

    def resource_valid?
      @resource = params[:resource]
      return true unless @resource
      return true if Object.const_get(@resource.classify)
    rescue NameError
      return false
    end
  end
end
