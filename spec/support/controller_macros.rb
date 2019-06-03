# rubocop:disable Metrics/BlockLength
# frozen_string_literal: true

module ControllerMacros
  def login_user
    before(:each) do
      @request.env['devise.mapping'] = Devise.mappings[:user]
      user = create :user
      user.confirm
      sign_in user
    end
  end

  def project_generator(options = {})
    before(:each) do
      user = create :user
      user.confirm
      team = create :team, created_by: user
      create :user_team, :admin, user: user, team: team
      sign_in user

      user_project = create :user_project, :owner, user: user
      project = create :project, team: team, user_projects: [user_project]

      @project = {
        project_comments: [],
        tags: [],
        experiments: [],
        my_modules: [],
        protocols: [],
        steps: [],
        step_comments: [],
        my_module_comments: [],
        repositories: [],
        repository_rows: [],
        results: [],
        result_assets: [],
        result_texts: [],
        result_tables: [],
        result_comments: [],

        # single forms
        user: user,
        team: team,
        project: project,
        project_comment: nil,
        tag: nil,
        experiment: nil,
        my_module: nil,
        protocol: nil,
        step: nil,
        step_comment: nil,
        my_module_comment: nil,
        repository: nil,
        repository_row: nil,
        result: nil,
        result_asset: nil,
        result_text: nil,
        result_table: nil,
        result_comment: nil
      }

      if options[:project_comments]
        @project[:project_comments] = create_list :project_comment, options[:project_comments],
                                                  project: project, user: user
      end

      @project[:tags] = create_list :tag, options[:tags], project: project if options[:tags]

      experiments = create_list :experiment, options[:experiments] || 1, project: project
      @project[:experiments] = experiments

      experiments.each do |experiment|
        my_modules = create_list :my_module, options[:my_modules] || 1, experiment: experiment
        @project[:my_modules] += my_modules

        my_modules.each do |my_module|
          protocol = create :protocol, my_module: my_module, team: team, added_by: user
          @project[:protocols].push(protocol)
          if options[:steps]
            steps = create_list :step, options[:steps], protocol: protocol, user: user
            @project[:steps] += steps
            steps.each do |step|
              if options[:step_comments]
                @project[:step_comments] += create_list :step_comment, options[:step_comments], user: user, step: step
              end
            end
          end

          if options[:my_module_comments]
            my_module_comments = create_list :task_comment, options[:my_module_comments],
                                             user: user, my_module: my_module
            @project[:my_module_comments] += my_module_comments
          end

          next unless options[:results]

          results = create_list :result, options[:results], my_module: my_module, user: user
          @project[:results] += results
          results.each do |result|
            if options[:result_assets]
              @project[:result_assets] += create_list :result_asset, options[:result_assets], result: result
            end
            if options[:result_texts]
              @project[:result_texts] += create_list :result_text, options[:result_texts], result: result
            end
            if options[:result_tables]
              @project[:result_tables] += create_list :result_table, options[:result_tables], result: result
            end
            if options[:result_comments]
              @project[:result_comments] += create_list :result_comment, options[:result_comments],
                                                        result: result, user: user
            end
          end
        end
      end

      if options[:repositories]
        repositories = create_list :repository, options[:repositories], created_by: user, team: team
        @project[:repositories] = repositories
        repositories.each do |repository|
          if options[:repository_rows]
            @project[:repository_rows] += create_list :repository_row, options[:repository_rows],
                                                      created_by: user, repository: repository
          end
        end
      end

      @project.each do |key, value|
        @project[key.to_s.singularize.to_sym] = value[0] if value.class == Array && value.length == 1
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
