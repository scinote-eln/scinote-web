class UserProject < ApplicationRecord
  enum role: { owner: 0, normal_user: 1, technician: 2, viewer: 3 }

  validates :role, presence: true
  validates :user, presence: true
  validates :project, presence: true

  belongs_to :user, inverse_of: :user_projects, optional: true
  belongs_to :assigned_by,
             foreign_key: 'assigned_by_id',
             class_name: 'User',
             optional: true
  belongs_to :project, inverse_of: :user_projects, optional: true

  before_destroy :destroy_associations

  after_commit do
    Views::Datatables::DatatablesReport.refresh_materialized_view
  end

  def role_str
    I18n.t("user_projects.enums.role.#{role.to_s}")
  end

  def destroy_associations
    # Destroy the user from all project's modules
    project.project_my_modules.each do |my_module|
      um2 = (my_module.user_my_modules.select { |um| um.user == self.user }).first
      if um2.present?
        um2.destroy
      end
    end
  end

end
