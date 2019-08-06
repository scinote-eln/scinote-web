# frozen_string_literal: true

module DelayedUploaderDemo
  # Get asset from demo_files folder
  def self.get_asset(user, team, file_name)
    asset = Asset.create(
      created_by: user,
      team: team,
      last_modified_by: user
    )
    asset.file.attach(io: File.open("#{Rails.root}/app/assets/demo_files/#{file_name}", 'r'), filename: file_name)
    asset
  end

  # Generates results asset for given module, file_name assumes file is located
  # in demo_files.
  def self.generate_result_asset(
    my_module:,
    current_user:,
    current_team:,
    result_name:,
    created_at: Time.now,
    file_name:,
    comment: nil
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

    # Generate comment if it exists
    generate_result_comment(temp_result, current_user, comment) if comment

    temp_asset.post_process_file(my_module.experiment.project.team)
  end

  # Adds asset to existing step
  def self.add_step_asset(step:, current_user:, current_team:, file_name:)
    temp_asset =
      DelayedUploaderDemo.get_asset(current_user, current_team, file_name)
    step.assets << temp_asset
    temp_asset.post_process_file(step.my_module.experiment.project.team)
  end

  def self.generate_result_comment(result, user, message, created_at = nil)
    created_at ||= result.created_at
    ResultComment.create(
      user: user,
      message: message,
      created_at: created_at,
      result: result
    )
  end
end
