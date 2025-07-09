# frozen_string_literal: true

json.array! @results do |r|
  json.array! [r.id, r.name]
end
