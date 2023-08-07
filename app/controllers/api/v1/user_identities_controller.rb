# frozen_string_literal: true

module Api
  module V1
    class UserIdentitiesController < BaseController
      before_action :load_user
      before_action :load_user_identity, only: %i(show update destroy)

      def index
        identities = timestamps_filter(@user.user_identities).page(params.dig(:page, :number))
                                                             .per(params.dig(:page, :size))
        render jsonapi: identities, each_serializer: UserIdentitySerializer
      end

      def create
        identity = @user.user_identities.create!(user_identity_params)
        render jsonapi: identity,
               serializer: UserIdentitySerializer,
               status: :created
      end

      def show
        render jsonapi: @identity, serializer: UserIdentitySerializer
      end

      def update
        @identity.attributes = update_user_identity_params
        if @identity.changed? && @identity.save!
          render jsonapi: @identity, serializer: UserIdentitySerializer
        else
          render body: nil, status: :no_content
        end
      end

      def destroy
        @identity.destroy!
        render body: nil
      end

      private

      def load_user
        @user = current_user if current_user.id == params[:user_id].to_i
        raise PermissionError.new(User, :read) unless @user
      end

      def load_user_identity
        @identity = @user.user_identities.find(params[:id].to_i)
      end

      def user_identity_params
        unless params.require(:data).require(:type) == 'user_identities'
          raise TypeError
        end
        params.require(:data).require(:attributes)
        params.permit(data: { attributes: %i(provider uid) })[:data]
      end

      def update_user_identity_params
        unless params.require(:data).require(:id).to_i == params[:id].to_i
          raise IDMismatchError
        end
        user_identity_params
      end
    end
  end
end
