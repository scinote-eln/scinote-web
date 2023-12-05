# frozen_string_literal: true

class UserMyModule < ApplicationRecord
  validates :user, presence: true, uniqueness: { scope: :my_module }
  validates :my_module, presence: true

  belongs_to :user, inverse_of: :user_my_modules, touch: true
  belongs_to :assigned_by, foreign_key: 'assigned_by_id', class_name: 'User', optional: true
  belongs_to :my_module, inverse_of: :user_my_modules, touch: true

  def log_activity(type_of, current_user)
    return if current_user.id == user.id

    Activities::CreateActivityService
      .call(activity_type: type_of,
            owner: current_user,
            team: my_module.experiment.project.team,
            project: my_module.experiment.project,
            subject: my_module,
            message_items: { my_module: my_module.id,
                             user_target: user.id })
  end
end
