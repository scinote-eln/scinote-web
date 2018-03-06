module SamplesHelper
  def all_custom_fields
    CustomField.where(team_id: @team).order(:created_at)
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
    elsif project_page?
      delete_samples_project_path(@project)
    elsif experiment_page?
      delete_samples_experiment_path(@experiment)
    end
  end
end
