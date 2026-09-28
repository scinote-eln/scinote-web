# frozen_string_literal: true

json.tasks do
  json.array! @my_modules.each do |my_module|
    json.id my_module.id
    json.name my_module.name
  end
end
