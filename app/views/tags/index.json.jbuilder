# frozen_string_literal: true

json.data do
  json.array! @tags do |t|
    json.id t.id
    json.name t.name
    json.color t.color
  end
end

json.permissions do
  json.can_create can_create_tags?(@team)
  json.can_update can_update_tags?(@team)
  json.can_delete can_delete_tags?(@team)
end
