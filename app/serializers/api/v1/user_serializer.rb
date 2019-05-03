# frozen_string_literal: true

module Api
  module V1
    class UserSerializer < ActiveModel::Serializer
      type :users
      attributes :full_name, :initials, :email
      attribute :avatar_file_name,
                if: -> { object.avatar.present? } { object.avatar_file_name }
      attribute :avatar_file_size,
                if: -> { object.avatar.present? } { object.avatar.size }
      attribute :avatar_url,
                if: -> { object.avatar.present? } { object.avatar.url(:icon) }
    end
  end
end
