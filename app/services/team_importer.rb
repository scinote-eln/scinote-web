class TeamImporter
  def initialize
    @user_mappings = {}
    @notification_mappings = {}
    @repository_mappings = {}
    @custom_field_mappings = {}
    @project_mappings = {}
    @repository_column_mappings = {}
    @experiment_mappings = {}
    @my_module_group_mappings = {}
    @my_module_mappings = {}
    @protocol_mappings = {}
    @protocol_keyword_mappings = {}
    @step_mappings = {}
    @asset_mappings = {}
    @tag_mappings = {}
    @result_text_mappings = {}
    @repository_row_mappings = {}
    @repository_list_item_mappings = {}
    @result_mappings = {}
    @checklist_mappings = {}
    @table_mappings = {}

    @project_counter = 0
    @repository_counter = 0
    @repository_row_counter = 0
    @protocol_counter = 0
    @step_counter = 0
    @report_counter = 0
    @my_module_counter = 0
    @notification_counter = 0
    @result_counter = 0
    @asset_counter = 0
    @user_counter = 0
    @mce_asset_counter = 0
  end

  def import_from_dir(import_dir)
    MyModule.skip_callback(:create, :before, :create_blank_protocol)
    Activity.skip_callback(:create, :after, :generate_notification)
    Protocol.skip_callback(:save, :after, :update_linked_children)
    @import_dir = import_dir
    team_json = JSON.parse(File.read("#{@import_dir}/team_export.json"))
    team = Team.new(team_json['team'].slice(*Team.column_names))
    team.id = nil
    team.transaction(isolation: :serializable) do
      team_creator_id = team.created_by_id
      team.created_by_id = nil
      team_last_modified_by = team.last_modified_by_id
      team.last_modified_by_id = nil
      team.save!

      create_users(team_json['users'], team)

      # Find new id of the first admin in the team
      @admin_id = @user_mappings[team_json['default_admin_id']]

      create_notifications(team_json['notifications'])

      puts 'Assigning users to the team...'
      team_json['user_teams'].each do |user_team_json|
        user_team = UserTeam.new(user_team_json)
        user_team.id = nil
        user_team.user_id = find_user(user_team.user_id)
        user_team.team_id = team.id
        user_team.assigned_by_id = find_user(user_team.assigned_by_id)
        user_team.save!
      end

      create_custom_fields(team_json['custom_fields'], team)
      create_protocol_keywords(team_json['protocol_keywords'], team)
      create_protocols(team_json['protocols'], nil, team)
      create_projects(team_json['projects'], team)
      create_repositories(team_json['repositories'], team)

      # Second run, we needed it because of some models should be created

      team_json['users'].each do |user_json|
        user_json['user_notifications'].each do |user_notification_json|
          user_notification = UserNotification.new(user_notification_json)
          user_notification.id = nil
          user_notification.user_id = find_user(user_notification.user_id)
          user_notification.notification_id =
            @notification_mappings[user_notification.notification_id]
          next if user_notification.notification_id.blank?
          user_notification.save!
        end

        user_json['repository_table_states'].each do |rep_tbl_state_json|
          rep_tbl_state = RepositoryTableState.new(rep_tbl_state_json)
          rep_tbl_state.id = nil
          rep_tbl_state.user_id = find_user(rep_tbl_state.user_id)
          rep_tbl_state.repository_id =
            @repository_mappings[rep_tbl_state.repository_id]
          rep_tbl_state.save!
        end
      end

      team_json['projects'].each do |project_json|
        create_activities(project_json['activities'])
        create_reports(project_json['reports'], team)
        project_json['experiments'].each do |experiment_json|
          experiment_json['my_modules'].each do |my_module_json|
            create_task_connections(my_module_json['outputs'])
          end
        end
      end

      team_json['repositories'].each do |repository_json|
        repository_json['repository_rows'].each do |repository_row_json|
          create_repository_cells(repository_row_json['repository_cells'], team)
        end
      end

      create_tiny_mce_assets(team_json['tiny_mce_assets'], team)
      update_smart_annotations(team)

      # restoring team's creator
      team.created_by_id = find_user(team_creator_id)
      team.last_modified_by_id = find_user(team_last_modified_by)
      team.save!

      puts "Imported users: #{@user_counter}"
      puts "Imported notifications: #{@notification_counter}"
      puts "Imported projects: #{@project_counter}"
      puts "Imported reports: #{@report_counter}"
      puts "Imported repositories: #{@repository_counter}"
      puts "Imported repository rows: #{@repository_row_counter}"
      puts "Imported tasks: #{@my_module_counter}"
      puts "Imported protocols: #{@protocol_counter}"
      puts "Imported steps: #{@step_counter}"
      puts "Imported results: #{@result_counter}"
      puts "Imported assets: #{@asset_counter}"
      puts "Imported tinyMCE assets: #{@mce_asset_counter}"

      MyModule.set_callback(:create, :before, :create_blank_protocol)
      Activity.set_callback(:create, :after, :generate_notification)
      Protocol.set_callback(:save, :after, :update_linked_children)
    end
  end

  private

  def update_smart_annotations(team)
    team.projects.each do |pr|
      pr.project_comments.each do |comment|
        comment.save! if update_annotation(comment.message)
      end
      pr.experiments.each do |exp|
        exp.save! if update_annotation(exp.description)
        exp.my_modules.each do |task|
          task.task_comments.each do |comment|
            comment.save! if update_annotation(comment.message)
          end
          task.save! if update_annotation(task.description)
          task.protocol.steps.each do |step|
            step.step_comments.each do |comment|
              comment.save! if update_annotation(comment.message)
            end
            step.save! if update_annotation(step.description)
          end
          task.results.each do |res|
            res.result_comments.each do |comment|
              comment.save! if update_annotation(comment.message)
            end
            next unless res.result_text
            res.save! if update_annotation(res.result_text.text)
          end
        end
      end
    end
    team.protocols.where(my_module: nil).each do |protocol|
      protocol.steps.each do |step|
        step.step_comments.each do |comment|
          comment.save! if update_annotation(comment.message)
        end
        step.save! if update_annotation(step.description)
      end
    end
    team.repositories.each do |rep|
      rep.repository_rows.find_each do |row|
        row.repository_cells.each do |cell|
          cell.value.save! if update_annotation(cell.value.data)
        end
      end
    end
  end

  # Returns true if text was updated
  def update_annotation(text)
    return false if text.nil?
    updated = false
    %w(prj exp tsk rep_item).each do |name|
      text.scan(/~#{name}~\w+\]/).each do |text_match|
        orig_id_encoded = text_match.match(/~#{name}~(\w+)\]/)[1]
        orig_id = orig_id_encoded.base62_decode
        new_id =
          case name
          when 'prj'
            @project_mappings[orig_id]
          when 'exp'
            @experiment_mappings[orig_id]
          when 'tsk'
            @my_module_mappings[orig_id]
          when 'rep_item'
            @repository_row_mappings[orig_id]
          end
        next unless new_id
        new_id_encoded = new_id.base62_encode
        text.sub!("~#{name}~#{orig_id_encoded}]", "~#{name}~#{new_id_encoded}]")
        updated = true
      end
    end
    text.scan(/\[@[\w+-@?! ]+~\w+\]/).each do |user_match|
      orig_id_encoded = user_match.match(/\[@[\w+-@?! ]+~(\w+)\]/)[1]
      orig_id = orig_id_encoded.base62_decode
      next unless @user_mappings[orig_id]
      new_id_encoded = @user_mappings[orig_id].base62_encode
      text.sub!("~#{orig_id_encoded}]", "~#{new_id_encoded}]")
      updated = true
    end
    updated
  end

  def create_task_connections(connections_json)
    connections_json.each do |connection_json|
      connection = Connection.new(connection_json)
      connection.id = nil
      connection.input_id = @my_module_mappings[connection.input_id]
      connection.output_id = @my_module_mappings[connection.output_id]
      connection.save!
    end
  end

  def create_activities(activities_json)
    activities_json.each do |activity_json|
      activity = Activity.new(activity_json)
      activity.id = nil
      activity.user_id = find_user(activity.user_id)
      activity.project_id = @project_mappings[activity.project_id]
      activity.experiment_id =
        @experiment_mappings[activity.experiment_id]
      activity.my_module_id = @my_module_mappings[activity.my_module_id]
      activity.save!
    end
  end

  def create_tiny_mce_assets(tmce_assets_json, team)
    tmce_assets_json.each do |tiny_mce_asset_json|
      tiny_mce_asset = TinyMceAsset.new(tiny_mce_asset_json)
      # Try to find and load file
      tiny_mce_file = File.open(
        File.join(@import_dir, 'tiny_mce_assets', tiny_mce_asset.id.to_s,
                  tiny_mce_asset.image_file_name)
      )
      orig_tmce_id = tiny_mce_asset.id
      tiny_mce_asset.id = nil
      if tiny_mce_asset.step_id.present?
        tiny_mce_asset.step_id = @step_mappings[tiny_mce_asset.step_id]
      end
      if tiny_mce_asset.result_text_id.present?
        tiny_mce_asset.result_text_id =
          @result_text_mappings[tiny_mce_asset.result_text_id]
      end
      tiny_mce_asset.team = team
      tiny_mce_asset.image = tiny_mce_file
      tiny_mce_asset.save!
      @mce_asset_counter += 1
      if tiny_mce_asset.step_id.present?
        step = Step.find_by_id(tiny_mce_asset.step_id)
        step.description.sub!("[~tiny_mce_id:#{orig_tmce_id}]",
                              "[~tiny_mce_id:#{tiny_mce_asset.id}]")
        step.save!
      end
      if tiny_mce_asset.result_text_id.present?
        result_text = ResultText.find_by_id(tiny_mce_asset.result_text_id)
        result_text.text.sub!("[~tiny_mce_id:#{orig_tmce_id}]",
                              "[~tiny_mce_id:#{tiny_mce_asset.id}]")
      end
    end
  end

  def create_users(users_json, team)
    puts 'Creating users...'
    users_json.each do |user_json|
      user = User.new(user_json['user'].slice(*User.column_names))
      orig_user_id = user.id
      user.id = nil
      user.password = user_json['user']['encrypted_password']
      user.current_team_id = team.id
      user.invited_by_id = @user_mappings[user.invited_by_id]
      if user.avatar.present?
        avatar_path = File.join(@import_dir, 'avatars', orig_user_id.to_s,
                                user.avatar_file_name)
        user.avatar = File.open(avatar_path) if File.exist?(avatar_path)
      end
      user.save!
      @user_counter += 1
      user.update_attribute('encrypted_password',
                            user_json['user']['encrypted_password'])
      @user_mappings[orig_user_id] = user.id
      user_json['user_identities'].each do |user_identity_json|
        user_identity = UserIdentity.new(user_identity_json)
        user_identity.id = nil
        user_identity.user_id = user.id
        user_identity.save!
      end
    end
  end

  def create_notifications(notifications_json)
    puts 'Creating notifications...'
    notifications_json.each do |notification_json|
      notification = Notification.new(notification_json)
      next if notification.type_of.blank?
      orig_notification_id = notification.id
      notification.id = nil
      notification.generator_user_id = find_user(notification.generator_user_id)
      notification.save!
      @notification_mappings[orig_notification_id] = notification.id
      @notification_counter += 1
    end
  end

  def create_repositories(repositories_json, team)
    puts 'Creating repositories...'
    repositories_json.each do |repository_json|
      repository = Repository.new(repository_json['repository'])
      orig_repository_id = repository.id
      repository.id = nil
      repository.team = team
      repository.created_by_id = find_user(repository.created_by_id)
      repository.save!
      @repository_mappings[orig_repository_id] = repository.id
      @repository_counter += 1
      repository_json['repository_columns'].each do |repository_column_json|

        repository_column = RepositoryColumn.new(
          repository_column_json['repository_column']
        )
        orig_rep_col_id = repository_column.id
        repository_column.id = nil
        repository_column.repository = repository
        repository_column.created_by_id =
          find_user(repository_column.created_by_id)
        repository_column.save!
        @repository_column_mappings[orig_rep_col_id] = repository_column.id
        next unless repository_column.data_type == 'RepositoryListValue'
        repository_column_json['repository_list_items'].each do |list_item|
          created_by_id = find_user(repository_column.created_by_id)
          repository_list_item = RepositoryListItem.new(data: list_item['data'])
          repository_list_item.repository_column = repository_column
          repository_list_item.repository = repository
          repository_list_item.created_by_id = created_by_id
          repository_list_item.last_modified_by_id = created_by_id
          repository_list_item.save!
          @repository_list_item_mappings[list_item['id']] =
            repository_list_item.id
        end
      end
      create_repository_rows(repository_json['repository_rows'], repository)
    end
  end

  def create_repository_rows(repository_rows_json, repository)
    repository_rows_json.each do |repository_row_json|
      repository_row =
        RepositoryRow.new(repository_row_json['repository_row'])
      orig_rep_row_id = repository_row.id
      repository_row.id = nil
      repository_row.repository = repository
      repository_row.created_by_id = find_user(repository_row.created_by_id)
      repository_row.last_modified_by_id =
        find_user(repository_row.last_modified_by_id)
      repository_row.save!
      @repository_row_mappings[orig_rep_row_id] = repository_row.id
      @repository_row_counter += 1
      repository_row_json['my_module_repository_rows'].each do |mm_rep_row_json|
        mm_rep_row = MyModuleRepositoryRow.new(mm_rep_row_json)
        mm_rep_row.id = nil
        mm_rep_row.repository_row = repository_row
        mm_rep_row.my_module_id = @my_module_mappings[mm_rep_row.my_module_id]
        mm_rep_row.assigned_by_id = find_user(mm_rep_row.assigned_by_id)
        mm_rep_row.save!
      end
    end
  end

  def create_repository_cells(repository_cells_json, team)
    repository_cells_json.each do |repository_cell_json|
      repository_cell =
        RepositoryCell.new(repository_cell_json['repository_cell'])
      repository_cell.id = nil
      repository_cell.repository_column_id =
        @repository_column_mappings[repository_cell.repository_column_id]
      repository_cell.repository_row_id =
        @repository_row_mappings[repository_cell.repository_row_id]
      create_cell_value(repository_cell,
                        repository_cell_json,
                        team)
    end
  end

  def create_custom_fields(custom_fields_json, team)
    puts 'Creating custom fields...'
    custom_fields_json.each do |custom_field_json|
      custom_field = CustomField.new(custom_field_json)
      orig_custom_field_id = custom_field.id
      custom_field.id = nil
      custom_field.team = team
      custom_field.user_id = find_user(custom_field.user_id)
      custom_field.last_modified_by_id =
        find_user(custom_field.last_modified_by_id)
      custom_field.save!
      @custom_field_mappings[orig_custom_field_id] = custom_field.id
    end
  end

  def create_protocol_keywords(protocol_keywords_json, team)
    puts 'Creating keywords...'
    protocol_keywords_json.each do |protocol_keyword_json|
      protocol_keyword = ProtocolKeyword.new(protocol_keyword_json)
      orig_pr_keyword_id = protocol_keyword.id
      protocol_keyword.id = nil
      protocol_keyword.team = team
      protocol_keyword.save!
      @protocol_keyword_mappings[orig_pr_keyword_id] = protocol_keyword.id
    end
  end

  def create_projects(projects_json, team)
    puts 'Creating projects...'
    projects_json.each do |project_json|
      project = Project.new(project_json['project'])
      orig_project_id = project.id
      project.id = nil
      project.team = team
      project.created_by_id = find_user(project.created_by_id)
      project.last_modified_by_id = find_user(project.last_modified_by_id)
      project.archived_by_id = find_user(project.archived_by_id)
      project.restored_by_id = find_user(project.restored_by_id)
      project.save!
      @project_mappings[orig_project_id] = project.id
      @project_counter += 1
      puts 'Creating user_projects...'
      project_json['user_projects'].each do |user_project_json|
        user_project = UserProject.new(user_project_json)
        user_project.id = nil
        user_project.project = project
        user_project.user_id = find_user(user_project.user_id)
        user_project.assigned_by_id = find_user(user_project.assigned_by_id)
        user_project.save!
      end
      puts 'Creating project_comments...'
      project_json['project_comments'].each do |project_comment_json|
        project_comment = ProjectComment.new(project_comment_json)
        project_comment.id = nil
        project_comment.user_id = find_user(project_comment.user_id)
        project_comment.last_modified_by_id =
          find_user(project_comment.last_modified_by_id)
        project_comment.project = project
        project_comment.save!
      end
      puts 'Creating tags...'
      project_json['tags'].each do |tag_json|
        tag = Tag.new(tag_json)
        orig_tag_id = tag.id
        tag.id = nil
        tag.project = project
        tag.created_by_id = find_user(tag.created_by_id)
        tag.last_modified_by_id = find_user(tag.last_modified_by_id)
        tag.save!
        @tag_mappings[orig_tag_id] = tag.id
      end

      create_experiments(project_json['experiments'], project)
    end
  end

  def create_experiments(experiments_json, project)
    puts('Creating experiments...')
    experiments_json.each do |experiment_json|
      experiment = Experiment.new(experiment_json['experiment'])
      orig_experiment_id = experiment.id
      experiment.id = nil
      experiment.project = project
      experiment.created_by_id = find_user(experiment.created_by_id)
      experiment.last_modified_by_id = find_user(experiment.last_modified_by_id)
      experiment.archived_by_id = find_user(experiment.archived_by_id)
      experiment.restored_by_id = find_user(experiment.restored_by_id)
      experiment.save!
      @experiment_mappings[orig_experiment_id] = experiment.id
      experiment_json['my_module_groups'].each do |my_module_group_json|
        my_module_group = MyModuleGroup.new(my_module_group_json)
        orig_module_group_id = my_module_group.id
        my_module_group.id = nil
        my_module_group.experiment = experiment
        my_module_group.created_by_id =
          find_user(my_module_group.created_by_id)
        my_module_group.save!
        @my_module_group_mappings[orig_module_group_id] = my_module_group.id
      end
      experiment.delay.generate_workflow_img
      create_my_modules(experiment_json['my_modules'], experiment)
    end
  end

  def create_my_modules(my_modules_json, experiment)
    puts('Creating my_modules...')
    my_modules_json.each do |my_module_json|
      my_module = MyModule.new(my_module_json['my_module'])
      orig_my_module_id = my_module.id
      my_module.id = nil
      my_module.my_module_group_id =
        @my_module_group_mappings[my_module.my_module_group_id]
      my_module.created_by_id = find_user(my_module.created_by_id)
      my_module.last_modified_by_id =
        find_user(my_module.last_modified_by_id)
      my_module.archived_by_id = find_user(my_module.archived_by_id)
      my_module.restored_by_id = find_user(my_module.restored_by_id)
      my_module.experiment = experiment
      my_module.save!
      @my_module_mappings[orig_my_module_id] = my_module.id
      @my_module_counter += 1

      my_module_json['my_module_tags'].each do |my_module_tag_json|
        my_module_tag = MyModuleTag.new(my_module_tag_json)
        my_module_tag.id = nil
        my_module_tag.my_module = my_module
        my_module_tag.tag_id = @tag_mappings[my_module_tag.tag_id]
        my_module_tag.created_by_id =
          find_user(my_module_tag.created_by_id)
        my_module_tag.save!
      end

      my_module_json['task_comments'].each do |task_comment_json|
        task_comment = TaskComment.new(task_comment_json)
        task_comment.id = nil
        task_comment.user_id = find_user(task_comment.user_id)
        task_comment.last_modified_by_id =
          find_user(task_comment.last_modified_by_id)
        task_comment.my_module = my_module
        task_comment.save!
      end

      my_module_json['user_my_modules'].each do |user_module_json|
        user_module = UserMyModule.new(user_module_json)
        user_module.id = nil
        user_module.my_module = my_module
        user_module.user_id = find_user(user_module.user_id)
        user_module.assigned_by_id =
          find_user(user_module.assigned_by_id)
        user_module.save!
      end
      create_protocols(my_module_json['protocols'], my_module)

      create_results(my_module_json['results'], my_module)
    end
  end

  def create_protocols(protocols_json, my_module = nil, team = nil)
    puts 'Creating protocols...'
    protocols_json.each do |protocol_json|
      protocol = Protocol.new(protocol_json['protocol'])
      orig_protocol_id = protocol.id
      protocol.id = nil
      protocol.added_by_id = find_user(protocol.added_by_id)
      protocol.team = team ? team : my_module.experiment.project.team
      protocol.archived_by_id = find_user(protocol.archived_by_id)
      protocol.restored_by_id = find_user(protocol.restored_by_id)
      protocol.my_module = my_module unless protocol.my_module_id.nil?
      unless protocol.parent_id.nil?
        protocol.parent_id = @protocol_mappings[protocol.parent_id]
      end
      protocol.save!
      @protocol_counter += 1
      @protocol_mappings[orig_protocol_id] = protocol.id

      protocol_json['protocol_protocol_keywords'].each do |pp_keyword_json|
        pp_keyword = ProtocolProtocolKeyword.new(pp_keyword_json)
        pp_keyword.id = nil
        pp_keyword.protocol = protocol
        pp_keyword.protocol_keyword_id =
          @protocol_keyword_mappings[pp_keyword.protocol_keyword_id]
        pp_keyword.save!
      end
      create_steps(protocol_json['steps'], protocol)
    end
  end

  def create_steps(steps_json, protocol)
    puts('Creating steps...')
    steps_json.each do |step_json|
      step = Step.new(step_json['step'])
      orig_step_id = step.id
      step.id = nil
      step.user_id = find_user(step.user_id)
      step.last_modified_by_id = find_user(step.last_modified_by_id)
      step.protocol_id = protocol.id
      step.save!
      @step_mappings[orig_step_id] = step.id
      @step_counter += 1

      step_json['step_comments'].each do |step_comment_json|
        step_comment = StepComment.new(step_comment_json)
        step_comment.id = nil
        step_comment.user_id = find_user(step_comment.user_id)
        step_comment.last_modified_by_id =
          find_user(step_comment.last_modified_by_id)
        step_comment.step = step
        step_comment.save!
      end

      step_json['tables'].each do |table_json|
        table = Table.new(table_json)
        orig_table_id = table.id
        table.id = nil
        table.created_by_id = find_user(table.created_by_id)
        table.last_modified_by_id =
          find_user(table.last_modified_by_id)
        table.team = protocol.team
        table.contents = Base64.decode64(table.contents)
        table.data_vector = Base64.decode64(table.data_vector)
        table.save!
        @table_mappings[orig_table_id] = table.id
        StepTable.create!(step: step, table: table)
      end

      step_json['assets'].each do |asset_json|
        asset = create_asset(asset_json, protocol.team)
        StepAsset.create!(step: step, asset: asset)
      end

      create_step_checklists(step_json['checklists'], step)
    end
  end

  def create_results(results_json, my_module)
    puts('Creating results...')
    results_json.each do |result_json|
      result = Result.new(result_json['result'])
      orig_result_id = result.id
      result.id = nil
      result.my_module = my_module
      result.user_id = find_user(result.user_id)
      result.last_modified_by_id = find_user(result.last_modified_by_id)
      result.archived_by_id = find_user(result.archived_by_id)
      result.restored_by_id = find_user(result.restored_by_id)

      if result_json['table'].present?
        table = Table.new(result_json['table'])
        orig_table_id = table.id
        table.id = nil
        table.created_by_id = find_user(table.created_by_id)
        table.last_modified_by_id =
          find_user(table.last_modified_by_id)
        table.team = my_module.experiment.project.team
        table.contents = Base64.decode64(table.contents)
        table.data_vector = Base64.decode64(table.data_vector)
        table.save!
        @table_mappings[orig_table_id] = table.id
        result.table = table
      end

      if result_json['asset'].present?
        asset = create_asset(result_json['asset'],
                             my_module.experiment.project.team)
        result.asset = asset
      end

      if result_json['result_text'].present?
        result_text = ResultText.new(result_json['result_text'])
        orig_result_text_id = result_text.id
        result_text.id = nil
        result_text.result = result
        result_text.save!
        @result_text_mappings[orig_result_text_id] = result_text.id
      end

      result.save!
      @result_mappings[orig_result_id] = result.id
      @result_counter += 1

      result_json['result_comments'].each do |result_comment_json|
        result_comment = ResultComment.new(result_comment_json)
        result_comment.id = nil
        result_comment.user_id = find_user(result_comment.user_id)
        result_comment.last_modified_by_id =
          find_user(result_comment.last_modified_by_id)
        result_comment.result = result
        result_comment.save!
      end
    end
  end

  # returns asset object
  def create_asset(asset_json, team)
    asset = Asset.new(asset_json)
    orig_asset_id = asset.id
    file =
      File.open("#{@import_dir}/assets/#{asset.id}/#{asset.file_file_name}")
    asset.id = nil
    asset.created_by_id = find_user(asset.created_by_id)
    asset.last_modified_by_id =
      find_user(asset.last_modified_by_id)
    asset.team = team
    asset.file = file
    asset.save!
    @asset_mappings[orig_asset_id] = asset.id
    @asset_counter += 1
    asset
  end

  def create_step_checklists(step_checklists_json, step)
    step_checklists_json.each do |checklist_json|
      checklist = Checklist.new(checklist_json['checklist'])
      orig_checklist_id = checklist.id
      checklist.id = nil
      checklist.step = step
      checklist.created_by_id = find_user(checklist.created_by_id)
      checklist.last_modified_by_id =
        find_user(checklist.last_modified_by_id)
      checklist.save!
      @checklist_mappings[orig_checklist_id] = checklist.id
      checklist_json['checklist_items'].each do |checklist_item_json|
        checklist_item = ChecklistItem.new(checklist_item_json)
        checklist_item.id = nil
        checklist_item.checklist = checklist
        checklist_item.created_by_id = find_user(checklist_item.created_by_id)
        checklist_item.last_modified_by_id =
          find_user(checklist_item.last_modified_by_id)
        checklist_item.save!
      end
    end
  end

  def create_reports(reports_json, team)
    reports_json.each do |report_json|
      report_el_parent_mappings = {}
      report_element_mappings = {}
      report = Report.new(report_json['report'])
      report.id = nil
      report.project_id = @project_mappings[report.project_id]
      report.user_id = find_user(report.user_id)
      report.last_modified_by_id = find_user(report.last_modified_by_id)
      report.team_id = team.id
      report.save!
      @report_counter += 1
      report_json['report_elements'].each do |report_element_json|
        report_element = ReportElement.new(report_element_json)
        orig_report_element_id = report_element.id
        report_element.id = nil
        orig_parent_id = report_element.parent_id
        report_element.parent_id = nil
        report_element.report = report
        if report_element.project_id
          report_element.project_id =
            @project_mappings[report_element.project_id]
        end
        if report_element.my_module_id
          report_element.my_module_id =
            @my_module_mappings[report_element.my_module_id]
        end
        if report_element.step_id
          report_element.step_id = @step_mappings[report_element.step_id]
        end
        if report_element.result_id
          report_element.result_id = @result_mappings[report_element.result_id]
        end
        if report_element.checklist_id
          report_element.checklist_id =
            @checklist_mappings[report_element.checklist_id]
        end
        if report_element.asset_id
          report_element.asset_id = @asset_mappings[report_element.asset_id]
        end
        if report_element.table_id
          report_element.table_id = @table_mappings[report_element.table_id]
        end
        if report_element.experiment_id
          report_element.experiment_id =
            @experiment_mappings[report_element.experiment_id]
        end
        if report_element.repository_id
          report_element.repository_id =
            @repository_mappings[report_element.repository_id]
        end
        report_element.save!
        report_element_mappings[orig_report_element_id] = report_element.id
        report_el_parent_mappings[report_element.id] = orig_parent_id
      end
      report_el_parent_mappings.each do |k, v|
        re = ReportElement.find_by_id(k)
        re.parent_id = report_element_mappings[v]
        re.save!
      end
    end
  end

  def find_user(user_id)
    return nil if user_id.nil?
    @user_mappings[user_id] ? @user_mappings[user_id] : @admin_id
  end

  def find_list_item_id(list_item_id)
    @repository_list_item_mappings[list_item_id]
  end

  def create_cell_value(repository_cell, value_json, team)
    cell_json = value_json['repository_value']
    case repository_cell.value_type
    when 'RepositoryListValue'
      list_item_id = find_list_item_id(cell_json['repository_list_item_id'])
      repository_value = RepositoryListValue.new(
        repository_list_item_id: list_item_id.to_i
      )
    when 'RepositoryTextValue'
      repository_value = RepositoryTextValue.new(cell_json)
    when 'RepositoryAssetValue'
      asset = create_asset(value_json['repository_value_asset'], team)
      repository_value = RepositoryAssetValue.new(asset: asset)
    end
    repository_value.id = nil
    repository_value.created_by_id = find_user(cell_json['created_by_id'])
    repository_value.last_modified_by_id =
      find_user(cell_json['last_modified_by_id'])
    repository_value.repository_cell = repository_cell
    repository_value.save!
  end
end
