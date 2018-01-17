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
      obj = @resource.fetch(:type)
                     .constantize
                     .public_send(:find_by_id, @resource.fetch(:id) {
                       raise ArgumentError, 'ID must be present'
                     }) if @resource
      @required_permissions.each do |permission|
        trim_permission = permission.gsub('can_', '')
        if @resource
          # return false if object does not exist
          result = obj ? @holder.eval(trim_permission, current_user, obj) : false
          @permissions.merge!(permission => result)
        else
          @permissions.merge!(
            permission => @holder.eval_generic(
              trim_permission, current_user
            )
          )
        end
      end
    end

    def sanitize_permissions!
      @required_permissions = params.fetch(:requiredPermissions) do
        :permissions_array_missing
      end
      @holder = Canaid::PermissionsHolder.instance
      @required_permissions.each do |permission|
        next if @holder.has_permission?(permission.gsub('can_', ''))
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
      return true if Object.const_get(@resource.fetch(:type).classify)
    rescue NameError
      return false
    end
  end
end
