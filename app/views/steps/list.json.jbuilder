# frozen_string_literal: true

json.array! @steps do |s|
  json.array! [s.id, s.label]
end
