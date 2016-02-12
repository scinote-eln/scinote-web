class MyModuleComment < ActiveRecord::Base
  validates :comment, :my_module, presence: true
  validates :my_module_id, uniqueness: { scope: :comment_id }

  belongs_to :comment, inverse_of: :my_module_comment
  belongs_to :my_module, inverse_of: :my_module_comments
end
