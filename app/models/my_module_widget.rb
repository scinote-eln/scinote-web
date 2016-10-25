class MyModuleWidget < ActiveRecord::Base
  enum widget_type: Constants::MY_MODULE_WIDGET_TYPES

  after_destroy :update_other_widget_positions

  validates :widget_type, presence: true
  validates :position,
            presence: true,
            uniqueness: { scope: :my_module_id },
            numericality: { greater_than_or_equal_to: 0 }
  validates :properties, exclusion: { in: [nil] }
  validates :added_by_id, presence: true

  belongs_to :added_by, class_name: 'User', inverse_of: :added_my_module_widgets
  belongs_to :last_modified_by,
             class_name: 'User',
             inverse_of: :last_modified_my_module_widgets
  belongs_to :my_module, inverse_of: :my_module_widgets

  private

  def update_other_widget_positions
    # Update position on other module widgets of this widget's module
    my_module.my_module_widgets
             .where('position > ?', position)
             .each do |widget|
      widget.position -= 1
      widget.save!
    end
  end
end
