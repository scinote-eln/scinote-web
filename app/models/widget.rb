class Widget < ActiveRecord::Base
  enum widget_type: Constants::WIDGET_TYPES

  validates :widget_type, presence: true
  validates :position,
            presence: true,
            numericality: { greater_than_or_equal_to: 0 }
  validates :my_module_id, uniqueness: { scope: :position }
  store :properties, coder: JSON

  belongs_to :added_by, class_name: 'User', inverse_of: :added_widgets
  belongs_to :last_modified_by,
             class_name: 'User',
             inverse_of: :last_modified_widgets
  belongs_to :my_module, inverse_of: :widgets
end
