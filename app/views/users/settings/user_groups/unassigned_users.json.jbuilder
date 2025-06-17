# frozen_string_literal: true

json.data do
  json.array! @unassigned_users do |user|
    json.array! [
      user.id,
      user.name,
      {
        avatar: avatar_path(user, :icon_small)
      }
    ]
  end
end
