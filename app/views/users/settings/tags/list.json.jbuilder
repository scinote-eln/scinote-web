# frozen_string_literal: true

json.data do
  json.array! @tags do |t|
    json.array! [t.id, t.name, t.color]
  end
end
