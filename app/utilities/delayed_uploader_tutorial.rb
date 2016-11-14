module DelayedUploaderTutorial
  # Get asset from tutorial_files folder
  def self.get_asset(user, file_name)
    Asset.new(
      file: File.open(
        "#{Rails.root}/app/assets/tutorial_files/#{file_name}", 'r'
      ),
      created_by: user,
      last_modified_by: user
    )
  end

  # Generates results asset for given module, file_name assumes file is located
  # in tutorial_files.
  def self.generate_result_asset(
    my_module:,
    current_user:,
    result_name:,
    created_at: Time.now,
    file_name:
  )
    temp_asset = get_asset(current_user, file_name)
    temp_result = Result.new(
      created_at: created_at,
      user: current_user,
      my_module: my_module,
      name: result_name,
      asset: temp_asset
    )

    temp_result.save
    temp_asset.save
    temp_asset.post_process_file(my_module.experiment.project.organization)

    # Create result activity
    Activity.new(
      type_of: :add_result,
      project: my_module.experiment.project,
      my_module: my_module,
      user: current_user,
      created_at: temp_result.created_at,
      message: I18n.t(
        'activities.add_asset_result',
        user: current_user.full_name,
        result: temp_result.name
      )
    ).sneaky_save
  end

  # Adds asset to existing step
  def self.add_step_asset(step:, current_user:, file_name:)
    temp_asset = DelayedUploaderTutorial.get_asset(current_user, file_name)
    step.assets << temp_asset
    temp_asset.post_process_file(step.my_module.experiment.project.organization)
  end
end
