module ClientApi
  module Users
    class UsersController < ApplicationController
      def sign_out_user
        respond_to do |format|
          if sign_out current_user
            format.json { render json: {}, status: :ok }
          else
            format.json { render json: {}, status: :unauthorized }
          end
        end
      end

      def preferences_info
        respond_to do |format|
          format.json do
            render template: 'client_api/users/preferences',
                   status: :ok,
                   locals: { user: current_user }
          end
        end
      end

      def profile_info
        respond_to do |format|
          format.json do
            render template: '/client_api/users/profile',
                   status: :ok,
                   locals: { user: current_user }
          end
        end
      end

      def statistics_info
        respond_to do |format|
          format.json do
            render template: '/client_api/users/statistics',
                   status: :ok,
                   locals: { user: current_user }
          end
        end
      end

      def current_user_info
        respond_to do |format|
          format.json do
            render template: '/client_api/users/show',
                   status: :ok,
                   locals: { user: current_user }
          end
        end
      end

      def update
        service = ClientApi::Users::UpdateService.new(
          current_user: current_user,
          params: user_params
        )
        result = service.execute

        if result[:status] == :success
          bypass_sign_in(current_user)
          success_response
        else
          error_response(
            message: result[:message],
            details: service.user.errors
          )
        end
      end

      private

      def user_params
        params.require(:user)
              .permit(:password, :initials, :email, :full_name,
                      :password_confirmation, :current_password, :avatar,
                      :time_zone, :assignments_notification,
                      :assignments_email_notification, :recent_notification,
                      :recent_email_notification,
                      :system_message_email_notification,
                      :popovers_enabled)
      end

      def success_response(args = {})
        template = args.fetch(:template) { nil }
        locals = args.fetch(:locals) { {} }
        details = args.fetch(:details) { {} }

        respond_to do |format|
          format.json do
            if template
              render template: template,
                     status: :ok,
                     locals: locals
            else
              render json: { details: details }, status: :ok
            end
          end
        end
      end

      def error_response(args = {})
        message = args.fetch(:message) { t('client_api.generic_error_message') }
        details = args.fetch(:details) { {} }
        status = args.fetch(:status) { :unprocessable_entity }

        respond_to do |format|
          format.json do
            render json: {
              message: message,
              details: details
            },
            status: status
          end
        end
      end
    end
  end
end
