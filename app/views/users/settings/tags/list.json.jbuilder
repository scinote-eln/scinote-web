# frozen_string_literal: true

json.data do
  json.array! @tags do |t|
    json.id t.id
    json.name t.name
    json.color t.color
  end
end
