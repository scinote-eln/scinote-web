# frozen_string_literal: true

module Api
  module V1
    class UserSerializer < ActiveModel::Serializer
      type :users
      attributes :full_name, :initials, :email
      attribute :avatar_file_name, if: -> { object.avatar.attached? }
      attribute :avatar_file_size, if: -> { object.avatar.attached? }
      attribute :avatar_url, if: -> { object.avatar.attached? }

      include TimestampableModel

      def avatar_file_name
        object.avatar.blob.filename
      end

      def avatar_file_size
        object.avatar.blob.byte_size
      end

      def avatar_url
        object.avatar_url(:icon)
      end
    end
  end
end
