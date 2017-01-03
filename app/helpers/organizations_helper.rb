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
      sanitize_input("<div class='modal-tooltip'>#{truncate(name, length: len)}
		    <span class='modal-tooltiptext'>#{name}</span>
      </div>")
    else
      name
    end
  end
end
