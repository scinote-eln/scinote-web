# frozen_string_literal: true

module Api
  module V1
    class UserIdentitiesController < BaseController
      before_action :load_user
      before_action :load_user_identity, only: %i(show update destroy)

      def index
        identities = @user.user_identities
                          .page(params.dig(:page, :number))
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
          render body: nil
        end
      end

      def destroy
        @identity.destroy!
        render body: nil
      end

      private

      def load_user
        @user = current_user if current_user.id == params[:user_id].to_i
        return render body: nil, status: :forbidden unless @user
      end

      def load_user_identity
        @identity = @user.user_identities.find(params[:id].to_i)
      end

      def user_identity_params
        unless params.require(:data).require(:type) == 'user_identities'
          raise ActionController::BadRequest,
                'Wrong object type within parameters'
        end
        params.require(:data).require(:attributes)
        params.permit(data: { attributes: %i(provider uid) })[:data]
      end

      def update_user_identity_params
        unless params.require(:data).require(:id).to_i == params[:id].to_i
          raise ActionController::BadRequest,
                'Object ID mismatch in URL and request body'
        end
        user_identity_params
      end
    end
  end
end
