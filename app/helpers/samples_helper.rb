module SamplesHelper

  def can_add_samples
    module_page? && can_add_samples_to_module(@my_module)
  end

  def can_remove_samples
    module_page? && can_delete_samples_from_module(@my_module)
  end

  def can_add_sample_related_things_to_organization
    can_create_custom_field_in_organization(@organization) \
    or can_create_sample_type_in_organization(@organization) \
    or can_create_sample_group_in_organization(@organization)
  end

  def all_custom_fields
    CustomField.where(organization_id: @organization).order(:created_at)
  end

  def num_of_columns
    # Magic numbers, woohoo:
    # - 1 for checkbox column,
    # - 6 corresponds to initial number of basic sample columns (without
    # custom)
    1 + 6 + all_custom_fields.count
  end

  def form_submit_link
    if module_page?
      assign_samples_my_module_path(@my_module)
    elsif is_project_page?
      delete_samples_project_path(@project)
    end
  end

end
