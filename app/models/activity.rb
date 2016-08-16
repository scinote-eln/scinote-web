class Activity < ActiveRecord::Base
  enum type_of: [
    :create_project,
    :rename_project,
    :change_project_visibility,
    :archive_project,
    :restore_project,
    :assign_user_to_project,
    :change_user_role_on_project,
    :unassign_user_from_project,
    :create_module,
    :clone_module,
    :archive_module,
    :restore_module,
    :change_module_description,
    :assign_user_to_module,
    :unassign_user_from_module,
    :create_step,
    :destroy_step,
    :add_comment_to_step,
    :complete_step,
    :uncomplete_step,
    :check_step_checklist_item,
    :uncheck_step_checklist_item,
    :edit_step,
    :add_result,
    :add_comment_to_result,
    :archive_result,
    :edit_result,
    :clone_experiment,
    :move_experiment
  ]

  validates :type_of, presence: true
  validates :project, :user, presence: true

  belongs_to :project, inverse_of: :activities
  belongs_to :my_module, inverse_of: :activities
  belongs_to :user, inverse_of: :activities
end
