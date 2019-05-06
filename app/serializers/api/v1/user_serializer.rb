# frozen_string_literal: true

module Api
  module V1
    class UserSerializer < ActiveModel::Serializer
      type :users
      attributes :full_name, :initials, :email
      attribute :avatar_file_name, if: -> { object.avatar.present? }
      attribute :avatar_file_size, if: -> { object.avatar.present? }
      attribute :avatar_url, if: -> { object.avatar.present? }

      def avatar_file_name
        object.avatar_file_name
      end

      def avatar_file_size
        object.avatar.size
      end

      def avatar_url
        object.avatar.url(:icon)
      end
    end
  end
end
