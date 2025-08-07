# frozen_string_literal: true

module Lists
  class UserGroupMembershipSerializer < ActiveModel::Serializer
    include Rails.application.routes.url_helpers
    include Canaid::Helpers::PermissionsHelper

    attributes :id, :created_at, :name, :email

    def name
      object.user.full_name
    end

    def email
      object.user.email
    end

    def created_at
      I18n.l(object.created_at, format: :full_date)
    end
  end
end
