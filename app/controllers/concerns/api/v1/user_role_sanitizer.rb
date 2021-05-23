# frozen_string_literal: true

module Api
  module V1
    module UserRoleSanitizer
      extend ActiveSupport::Concern

      def incoming_role_name(role)
        case role
        when 'owner'
          I18n.t('user_roles.predefined.owner')
        when 'normal_user'
          I18n.t('user_roles.predefined.normal_user')
        when 'technician'
          I18n.t('user_roles.predefined.technician')
        when 'viewer'
          I18n.t('user_roles.predefined.viewer')
        else
          raise IncludeNotSupportedError
        end
      end
    end
  end
end
