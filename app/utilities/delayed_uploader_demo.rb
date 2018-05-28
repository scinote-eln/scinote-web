module DelayedUploaderDemo
  # Get asset from demo_files folder
  def self.get_asset(user, team, file_name)
    Asset.new(
      file: File.open(
        "#{Rails.root}/app/assets/demo_files/#{file_name}", 'r'
      ),
      created_by: user,
      team: team,
      last_modified_by: user
    )
  end

  # Generates results asset for given module, file_name assumes file is located
  # in demo_files.
  def self.generate_result_asset(
    my_module:,
    current_user:,
    current_team:,
    result_name:,
    created_at: Time.now,
    file_name:
  )
    temp_asset = get_asset(current_user, current_team, file_name)
    temp_result = Result.new(
      created_at: created_at,
      user: current_user,
      my_module: my_module,
      name: result_name,
      asset: temp_asset
    )

    temp_result.save
    temp_asset.save
    temp_asset.post_process_file(my_module.experiment.project.team)

    # Create result activity
    Activity.new(
      type_of: :add_result,
      project: my_module.experiment.project,
      my_module: my_module,
      user: current_user,
      created_at: temp_result.created_at,
      updated_at: temp_result.created_at,
      message: I18n.t(
        'activities.add_asset_result',
        user: current_user.full_name,
        result: temp_result.name
      )
    ).sneaky_save
  end

  # Adds asset to existing step
  def self.add_step_asset(step:, current_user:, current_team:, file_name:)
    temp_asset =
      DelayedUploaderDemo.get_asset(current_user, current_team, file_name)
    step.assets << temp_asset
    temp_asset.post_process_file(step.my_module.experiment.project.team)
  end
end
