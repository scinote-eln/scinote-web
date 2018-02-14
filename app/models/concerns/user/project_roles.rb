require 'aspector'

module User::ProjectRoles
  extend ActiveSupport::Concern

  aspector do
    # Check if user is member of project
    around %i(
      is_member_of_project?
      is_owner_of_project?
      is_user_of_project?
      is_user_or_higher_of_project?
      is_technician_of_project?
      is_technician_or_higher_of_project?
      is_viewer_of_project?
    ) do |proxy, *args, &block|
      if args[0]
        @user_project = user_projects.where(project: args[0]).take
        @user_project ? proxy.call(*args, &block) : false
      else
        false
      end
    end
  end

  def is_member_of_project?(project)
    # This is already checked by aspector, so just return true
    true
  end

  def is_creator_of_project?(project)
    project.created_by == self
  end

  def is_owner_of_project?(project)
    @user_project.owner?
  end

  def is_user_of_project?(project)
    @user_project.normal_user?
  end

  def is_user_or_higher_of_project?(project)
    @user_project.normal_user? or @user_project.owner?
  end

  def is_technician_of_project?(project)
    @user_project.technician?
  end

  def is_technician_or_higher_of_project?(project)
    @user_project.technician? or
      @user_project.normal_user? or
      @user_project.owner?
  end

  def is_viewer_of_project?(project)
    @user_project.viewer?
  end
end
