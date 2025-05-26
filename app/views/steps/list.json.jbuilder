# frozen_string_literal: true

json.array! @steps do |r|
  json.array! [
    r.id,
    r.name,
    {
      position: r.position
    }
  ]
end
