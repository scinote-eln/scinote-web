# frozen_string_literal: true

class EditingFlagSerializer < ActiveModel::Serializer
  attributes :id, :subject_type, :subject_id, :timeout_at, :user

  def user
    {
      id: object.user.id,
      name: object.user.full_name,
      email: object.user.email,
      avatar_url: object.user.avatar_url(:icon_small)
    }
  end
end
