class Widget < ActiveRecord::Base
  store :properties, coder: JSON

  validates :type, presence: true
  validates :position, presence: true

  enum type: Constants::WIDGET_TYPES
end
