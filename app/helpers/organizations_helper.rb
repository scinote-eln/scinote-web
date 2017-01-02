module OrganizationsHelper
  # resets the current organization if needed
  def current_organization_switch(org)
    if org != current_organization
      current_user.current_organization_id = org.id
      current_user.save
    end
  end

  def truncate_organization_name(name, len = Constants::NAME_TRUNCATION_LENGTH)
    if name.length > len
      "<div class='modal-tooltip'>#{truncate(sanitize_input(name), length: len)}
		    <span class='modal-tooltiptext'>#{sanitize_input(name)}</span>
      </div>".html_safe
    else
      name
    end
  end
end
