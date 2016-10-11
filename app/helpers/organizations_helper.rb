module OrganizationsHelper
  # resets the current organization if needed
  def current_organization_switch(org)
    if org != current_organization
      current_user.current_organization_id = org.id
      current_user.save
    end
  end
end
