class MyModuleTag < ApplicationRecord
  validates :my_module, :tag, presence: true
  validates :tag_id, uniqueness: { scope: :my_module_id }

  belongs_to :my_module, inverse_of: :my_module_tags
  belongs_to :created_by,
             foreign_key: 'created_by_id',
             class_name: 'User',
             optional: true
  belongs_to :tag, inverse_of: :my_module_tags
end
