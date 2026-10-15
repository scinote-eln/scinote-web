# frozen_string_literal: true

require 'rails_helper'

describe TeamImporter do
  describe '#import_template_experiment_from_dir' do
    context 'successful import of all different elements with given json' do
      # Constants
      TEMPLATE_DIR = "#{Rails.root}/spec/services/model_importers/" \
                     "test_experiment_data"
      USER_ID = 2
      PROJECT_ID = 2

      before :all do
        time = Time.new(2015, 8, 1, 14, 35, 0)

        # Create 2 users and 2 projects to check for a different ID (id = 2)
        # when importing to avoid any defaults
        create :user
        @user = create :user
        @team = create :team, created_by: @user
        create :project, name: 'Temp project', visibility: 1,
          team: @team, archived: false, created_at: time , created_by: @user

        @project = create :project, name: 'Project', visibility: 1, team: @team,
          archived: false, created_at: time , created_by: @user

        # Reassign if multiple tests are run
        PROJECT_ID = @project.id
        USER_ID = @user.id

        @team_importer = TeamImporter.new
        @exp = @team_importer.import_experiment_template_from_dir(TEMPLATE_DIR,
                                                                  PROJECT_ID,
                                                                  USER_ID)
        Experiments::GenerateWorkflowImageService.call(experiment: @exp)
        @exp.reload
      end

      describe 'Experiment variables' do
        it { expect(@exp.project.id).to eq PROJECT_ID }
        it { expect(@exp.name).to eq 'Experiment export' }
        it { expect(@exp.description).to eq 'My description' }

        it { expect(@exp.created_at).to eq '2019-01-21T13:27:53.342Z'.to_time }
        it { expect(@exp.created_by.id).to eq USER_ID }
        it { expect(@exp.last_modified_by.id).to eq USER_ID }

        it { expect(@exp.archived).to eq false }
        it { expect(@exp.archived_by_id).to be_nil }
        it { expect(@exp.archived_on).to be_nil }

        it { expect(@exp.restored_by_id).to be_nil }
        it { expect(@exp.restored_on).to be_nil }

        it { expect(@exp.workflowimg.attached?).to eq(true) }
      end

      describe 'Module groups' do
        # Module groups
        it { expect(@exp.my_module_groups.count).to eq 2 }
        it do
          expect(@exp.my_module_groups.pluck(:created_by_id)).to all eq(
            USER_ID
          )
        end
        it do
          expect(@exp.my_module_groups.pluck(:created_at)).to(
            match_array(['2019-01-21T13:32:46.449Z'.to_time,
                         '2019-01-21T13:32:46.460Z'.to_time])
          )
        end
        it do
          expect(@exp.my_module_groups.pluck(:updated_at)).to(
            match_array(['2019-01-21T13:32:46.449Z'.to_time,
                         '2019-01-21T13:32:46.460Z'.to_time])
          )
        end
        it do
          expect(@exp.my_modules.where(my_module_group: nil).count).to eq 2
        end
        it { expect(@exp.my_modules.archived.count).to eq 1 }
      end

      describe 'Connections' do
        it 'creates all connections between modules' do
          expect(Connection.all.count).to eq 3

          # Load known modules
          exp_design = @exp.my_modules.find_by(name: 'Experiment design')
          rna = @exp.my_modules.find_by(
            name: 'RNA quality & quantity - BIOANALYSER'
          )
          reverse = @exp.my_modules.find_by(
            name: 'Reverse transcription'
          )

          task1 = @exp.my_modules.find_by(name: 'Workflow 2 - task 1')
          task2 = @exp.my_modules.find_by(name: 'Workflow 2 - task 2')

          # Check connections
          expect(exp_design.outputs.first.input_id).to eq(
            rna.id
          )
          expect(rna.outputs.first.input_id).to eq(
            reverse.id
          )
          expect(task1.outputs.first.input_id).to eq(
            task2.id
          )

          # Others should be empty
          expect(task2.outputs).to be_empty
          expect(reverse.outputs).to be_empty
        end
      end

      describe 'Modules' do
        it 'imports all the modules' do
          team_json = JSON.parse(File.read("#{TEMPLATE_DIR}/experiment.json"))
          team_json['my_modules'].each do |my_module|
            json_module = my_module.dig('my_module')

            # Find DB mapped module
            name = json_module.dig('name')
            db_module = @exp.my_modules.find_by(name: name)

            expect(db_module.description).to eq json_module['description']
            expect(db_module.created_at).to eq json_module['created_at'].to_time
            expect(db_module.created_by_id).to eq USER_ID

            expect(db_module.updated_at).to eq json_module['updated_at'].to_time
            expect(db_module.last_modified_by_id).to eq USER_ID

            expect(db_module.archived).to eq json_module['archived']

            expect(db_module.state).to eq json_module['state']
            if json_module['completed_on']
              expect(db_module.completed_on).to eq(
                json_module['completed_on'].to_time
              )
            end

            if json_module['due_date']
              expect(db_module.due_date).to eq(
                json_module['due_date'].to_time
              )
            end

            # Coordinates and workflow
            expect(db_module.x).to eq json_module['x']
            expect(db_module.y).to eq json_module['y']
            expect(db_module.workflow_order).to eq(
              json_module['workflow_order']
            )

            # Check for lonely tasks
            expect(db_module.my_module_group_id).to be_nil if json_module['my_module_group_id'].nil?

            # Check if callbacks for protocols are turned off
            expect(db_module.protocols.count).to eq 1

            # Although rows are present in JSON, they shouldn't be imported
            expect(db_module.repository_rows.count).to be_zero

            # No tags should be imported
            expect(db_module.tags.count).to be_zero

            ###########
            # Protocols
            ###########
            db_protocol = db_module.protocols.first
            json_protocol = my_module['protocols'][0]['protocol']

            # Protocol object
            expect(db_protocol.name).to eq json_protocol['name']
            expect(db_protocol.description).to eq json_protocol['description']
            expect(db_protocol.created_at).to eq(
              json_protocol['created_at'].to_time
            )
            expect(db_protocol.updated_at).to eq(
              json_protocol['updated_at'].to_time
            )
            expect(db_protocol.archived_by_id).to be_nil
            expect(db_protocol.archived_on).to be_nil
            expect(db_protocol.restored_by_id).to be_nil
            expect(db_protocol.restored_on).to be_nil
            expect(db_protocol.authors).to eq json_protocol['authors']
            expect(db_protocol.parent_id).to eq json_protocol['parent_id']
            expect(db_protocol.protocol_type).to eq(
              json_protocol['protocol_type']
            )
            expect(db_protocol.team_id).to eq @team.id
            expect(db_protocol.nr_of_linked_children).to eq(
              json_protocol.dig('nr_of_linked_children')
            )

            #######
            # STEPS
            #######
            json_steps = my_module.dig('protocols')[0].dig('steps')
            json_steps.each do |json_step|
              json_step_obj = json_step.dig('step')
              db_step = db_protocol.steps.find_by(name: json_step_obj['name'])

              # Step object
              expect(db_step.updated_at).to eq(
                json_step_obj['updated_at'].to_time
              )
              expect(db_step.position).to eq json_step_obj['position']
              expect(db_step.last_modified_by_id).to eq USER_ID
              expect(db_step.completed).to eq json_step_obj['completed']

              if json_step_obj['completed']
                expect(db_step.completed_on).to eq(
                  json_step_obj['completed_on'].to_time
                )
              end

              # byebug

              element_counts = {
                step_texts: 0,
                step_tables: 0,
                checklists: 0
              }

              json_step['step_orderable_elements'].each do |element|
                if element['step_text']
                  element_counts[:step_texts] += 1
                  json_element = element['step_text']
                  db_element = db_step.step_texts.find_by(text: json_element['text'])

                  expect(db_element).not_to be_nil
                  expect(db_element.created_at).to eq(json_element['created_at'].to_time)
                  expect(db_element.updated_at).to eq(json_element['updated_at'].to_time)
                elsif element['table']
                  element_counts[:step_tables] += 1
                  json_element = element['table']
                  db_element = db_step.tables.find_by(contents: Base64.decode64(json_element['contents']))

                  expect(db_element.created_at).to eq(json_element['created_at'].to_time)
                  expect(db_element.updated_at).to eq(json_element['updated_at'].to_time)
                  expect(db_element.created_by_id).to eq USER_ID
                  expect(db_element.last_modified_by_id).to eq USER_ID
                  expect(db_element.team_id).to eq @team.id
                  expect(db_element.name).to eq(json_element['name'])
                  expect(db_element.data_vector).to eq(Base64.decode64(json_element['data_vector']))
                elsif element['checklist']
                  element_counts[:checklists] += 1
                  json_element = element['checklist']['checklist']
                  json_checklist_items = element['checklist']['checklist_items']
                  db_element = db_step.checklists.find_by(name: json_element['name'])

                  expect(db_element.created_at).to eq(json_element['created_at'].to_time)
                  expect(db_element.updated_at).to eq(json_element['updated_at'].to_time)
                  expect(db_element.created_by_id).to eq USER_ID
                  expect(db_element.last_modified_by_id).to eq USER_ID
                  expect(db_element.checklist_items.count).to eq(json_checklist_items.count)

                  json_checklist_items.each do |json_item|
                    db_item = db_element.checklist_items.find_by(
                      text: json_item['text']
                    )
                    expect(db_item.checked).to eq(json_item['checked'])
                    expect(db_item.position).to eq(json_item['position'])
                    expect(db_item.created_at).to eq(json_item['created_at'].to_time)
                    expect(db_item.updated_at).to eq(json_item['updated_at'].to_time)
                    expect(db_item.created_by_id).to eq USER_ID
                    expect(db_item.last_modified_by_id).to eq USER_ID
                  end
                end
              end

              element_counts.each do |type, count|
                expect(db_step.__send__(type).count).to eq(count)
              end

              # Step assets
              expect(db_step.assets.count).to eq(
                json_step['assets'].count
              )

              expect(db_step.step_assets.count).to eq(
                json_step['step_assets'].count
              )

              json_step['assets'].each do |json_asset|
                blob_id = ActiveRecord::Base.connection.execute(\
                  "SELECT active_storage_blobs.id "\
                  "FROM active_storage_blobs "\
                  "WHERE active_storage_blobs.filename = '#{json_asset['asset_blob']['filename']}' LIMIT 1"
                )
                db_asset = db_step.assets.joins(:file_attachment)
                                  .where('active_storage_attachments.blob_id' => blob_id.as_json[0]['id'].to_i).first

                # Basic fields
                expect(db_asset.created_at).to eq(
                  json_asset['asset']['created_at'].to_time
                )
                expect(db_asset.created_by_id).to eq USER_ID
                expect(db_asset.last_modified_by_id).to eq USER_ID
                expect(db_asset.team_id). to eq @team.id

                # Other fields
                expect(db_asset.blob.content_type).to eq(
                  json_asset['asset_blob']['content_type']
                )
                expect(db_asset.blob.byte_size).to eq(
                  json_asset['asset_blob']['byte_size']
                )
                expect(db_asset.blob.created_at).to be_within(10.seconds)
                  .of(Time.now)
                expect(db_asset.version).to eq(
                  json_asset['asset']['version']
                )
              end

              # Step comments
              expect(db_step.step_comments.count).to eq(
                json_step['step_comments'].count
              )
              json_step['step_comments'].each do |json_comment|
                db_comment = db_step.step_comments.find_by(
                  message: json_comment['message']
                )

                expect(db_comment.created_at).to eq(
                  json_comment['created_at'].to_time
                )
                expect(db_comment.updated_at).to eq(
                  json_comment['updated_at'].to_time
                )
                expect(db_comment.last_modified_by_id).to eq USER_ID
              end
            end

            # Task comments
            expect(db_module.task_comments.count).to eq(
              my_module['task_comments'].count
            )
            my_module['task_comments'].each do |json_comment|
              db_comment = db_module.task_comments.find_by(
                message: json_comment['message']
              )

              expect(db_comment.created_at).to eq(
                json_comment['created_at'].to_time
              )
              expect(db_comment.updated_at).to eq(
                json_comment['updated_at'].to_time
              )
              expect(db_comment.last_modified_by_id).to eq USER_ID
            end
            #
            # User assigns to the the module
            expect(db_module.user_my_modules.first.user_id).to eq USER_ID unless my_module['user_my_modules'].blank?
          end
        end
      end
    end
  end
  describe '#import_from_dir' do
    # Round trip: build a small but complete team, export it with
    # ModelExporters::TeamExporter and import it back as a new team.
    let(:user) { create :user, full_name: 'Exporter' }
    let(:member) { create :user, full_name: 'Member' }
    let!(:owner_role) { UserRole.find_predefined_owner_role }
    let!(:normal_user_role) { create :normal_user_role }
    let(:team) { create :team, created_by: user, name: 'Source team' }
    let(:project_folder) { create :project_folder, team: team, name: 'Parent folder' }
    let(:sub_folder) { create :project_folder, team: team, name: 'Sub folder', parent_folder: project_folder }
    let(:project) do
      create :project, team: team, created_by: user, name: 'Exported project', project_folder: sub_folder
    end
    let(:experiment) { create :experiment, project: project, created_by: user, name: 'Exported experiment' }
    let(:task_a) { create :my_module, experiment: experiment, created_by: user, name: 'Task A' }
    let(:task_b) { create :my_module, experiment: experiment, created_by: user, name: 'Task B' }
    let(:repository) { create :repository, team: team, created_by: user, name: 'Exported inventory' }
    let(:export_dir) do
      exporter = ModelExporters::TeamExporter.new(team.id)
      exporter.export_to_dir
      Rails.root.join(exporter.instance_variable_get(:@dir_to_export)).to_s
    end
    let(:importer) { described_class.new }

    def build_source_team
      team
      create_user_assignment(team, normal_user_role, member, user)
      create :user_identity, user: user, provider: 'azure', uid: 'source-uid'

      tag = create :tag, team: team, name: 'Exported tag', created_by: user, last_modified_by: user
      keyword = create :protocol_keyword, team: team, name: 'Exported keyword'

      repo_protocol = create :protocol, :in_repository_published_original,
                             team: team, name: 'Repository protocol', added_by: user
      create :protocol_protocol_keyword, protocol: repo_protocol, protocol_keyword: keyword
      repo_step = create :step, protocol: repo_protocol, user: user, name: 'Repo step'
      create :step_orderable_element, step: repo_step, position: 0,
                                      orderable: create(:step_text, step: repo_step, text: 'Repo step text')

      create :project_comment, project: project, user: user, message: 'Project comment'
      create :project_comment, project: project, user: user,
                               message: "See [#Task A~tsk~#{task_a.id.base62_encode}] by " \
                                        "[@Exporter~#{user.id.base62_encode}]"

      task_a.taggings.create!(tag: tag, created_by: user)
      create :task_comment, my_module: task_a, user: user, message: 'Task comment'
      create :user_my_module, my_module: task_a, user: user, assigned_by: user
      Connection.create!(input_id: task_b.id, output_id: task_a.id)

      step = create :step, protocol: task_a.protocol, user: user, name: 'Task step', position: 0
      create :step_comment, step: step, user: user, message: 'Step comment'
      create :step_orderable_element, step: step, position: 0,
                                      orderable: create(:step_text, step: step, text: 'Task step text')
      checklist = create :checklist, step: step, name: 'Exported checklist', created_by: user
      create :checklist_item, checklist: checklist, text: 'Checklist item', created_by: user
      create :step_orderable_element, step: step, position: 1, orderable: checklist
      step_table = create :step_table, step: step,
                                       table: create(:table, name: 'Step table', created_by: user, team: team)
      create :step_orderable_element, step: step, position: 2, orderable: step_table
      create :step_asset, step: step, asset: create(:asset, team: team, created_by: user)

      result = create :result, my_module: task_a, user: user, name: 'Exported result'
      create :result_comment, result: result, user: user, message: 'Result comment'
      result_text = create :result_text, result: result, text: 'Result text'
      create :result_orderable_element, result: result, position: 0, orderable: result_text
      tiny_mce_asset = create :tiny_mce_asset, team: team, object: result_text
      result_text.update_column(:text, "<p>Image <img data-mce-token=\"#{Base62.encode(tiny_mce_asset.id)}\"/></p>")
      result_table = create :result_table, result: result,
                                           table: create(:table, name: 'Result table', created_by: user, team: team)
      create :result_orderable_element, result: result, position: 1, orderable: result_table
      create :result_asset, result: result, asset: create(:asset, team: team, created_by: user)

      report = create :report, project: project, team: team, user: user, name: 'Exported report'
      parent_element = create :report_element, report: report, type_of: :experiment, experiment: experiment
      create :report_element, report: report, type_of: :my_module, my_module: task_a, parent: parent_element

      text_column = create :repository_column, repository: repository, created_by: user,
                                               name: 'Text column', data_type: 'RepositoryTextValue'
      list_column = create :repository_column, repository: repository, created_by: user,
                                               name: 'List column', data_type: 'RepositoryListValue'
      status_column = create :repository_column, repository: repository, created_by: user,
                                                 name: 'Status column', data_type: 'RepositoryStatusValue'
      checklist_column = create :repository_column, repository: repository, created_by: user,
                                                    name: 'Checklist column', data_type: 'RepositoryChecklistValue'
      list_item = create :repository_list_item, repository_column: list_column, data: 'List item',
                                                created_by: user, last_modified_by: user
      status_item = create :repository_status_item, repository_column: status_column, status: 'Done',
                                                    created_by: user
      checklist_item = create :repository_checklist_item, repository_column: checklist_column,
                                                          data: 'Check item', created_by: user
      row = create :repository_row, repository: repository, created_by: user, name: 'Exported row'
      create :repository_text_value, data: 'Cell text', created_by: user, last_modified_by: user,
                                     repository_cell_attributes: { repository_row: row,
                                                                   repository_column: text_column }
      create :repository_list_value, repository_list_item: list_item, created_by: user, last_modified_by: user,
                                     repository_cell_attributes: { repository_row: row,
                                                                   repository_column: list_column }
      create :repository_status_value, repository_status_item: status_item, created_by: user,
                                       last_modified_by: user,
                                       repository_cell_attributes: { repository_row: row,
                                                                     repository_column: status_column }
      checklist_value = RepositoryChecklistValue.new(created_by: user, last_modified_by: user,
                                                     repository_checklist_items: [checklist_item])
      checklist_value.repository_cell = RepositoryCell.new(repository_row: row, repository_column: checklist_column)
      checklist_value.save!
      asset_column = create :repository_column, repository: repository, created_by: user,
                                                name: 'Asset column', data_type: 'RepositoryAssetValue'
      RepositoryAssetValue.create!(asset: create(:asset, team: team, created_by: user),
                                   created_by: user, last_modified_by: user,
                                   repository_cell: RepositoryCell.new(repository_row: row,
                                                                       repository_column: asset_column))
      create :mm_repository_row, repository_row: row, my_module: task_a, assigned_by: user
      create :repository_snapshot, original_repository: repository, my_module: task_a, name: 'Exported snapshot'
      create :repository_table_state, user: user, repository: repository, state: { 'order' => [] }

      ZebraLabelTemplate.create!(team: team, name: 'Exported label', content: '^XA^XZ',
                                 created_by: user, last_modified_by: user)

      create :activity, team: team, owner: user, subject: team, project: nil, type_of: :create_project
      create :activity, team: team, owner: user, subject: project, project: project, type_of: :create_project
    end

    def rewrite_unique_fields!(dir)
      path = File.join(dir, 'team_export.json')
      json = JSON.parse(File.read(path))
      json['users'].each do |user_json|
        user_json['user']['email'] = "imported-#{user_json['user']['email']}"
        user_json['user_identities'].each { |identity| identity['uid'] = "imported-#{identity['uid']}" }
      end
      File.write(path, json.to_json)
    end

    around do |example|
      example.run
    ensure
      MyModule.set_callback(:create, :before, :create_blank_protocol) unless
        MyModule._create_callbacks.any? { |c| c.filter == :create_blank_protocol }
      Activity.set_callback(:create, :before, :add_user) unless
        Activity._create_callbacks.any? { |c| c.filter == :add_user }
      Activity.set_callback(:initialize, :after, :init_default_values) unless
        Activity._initialize_callbacks.any? { |c| c.filter == :init_default_values }
    end

    before do
      # Nested transactions (DatabaseCleaner) cannot change isolation level
      allow(Team).to receive(:transaction).and_wrap_original { |method, **_opts, &block| method.call(&block) }
      allow(importer).to receive(:puts)
      allow_any_instance_of(ModelExporters::TeamExporter).to receive(:puts)
      build_source_team
      rewrite_unique_fields!(export_dir)
    end

    after do
      FileUtils.rm_rf(export_dir) if export_dir.present?
    end

    let(:imported_team) { Team.where(name: 'Source team').where.not(id: team.id).first }

    it 'creates a new team with imported users and memberships' do
      expect { importer.import_from_dir(export_dir) }.to change(Team, :count).by(1)

      imported_user = User.find_by(email: "imported-#{user.email}")
      imported_member = User.find_by(email: "imported-#{member.email}")
      expect(imported_user).to be_present
      expect(imported_user.current_team_id).to eq imported_team.id
      expect(imported_user.encrypted_password).to eq user.encrypted_password
      expect(imported_user.user_identities.pluck(:uid)).to eq ['imported-source-uid']
      expect(imported_team.created_by_id).to eq imported_user.id
      expect(imported_team.user_assignments.find_by(user: imported_member).user_role).to eq normal_user_role
    end

    it 'imports tags, keywords, folders and repository protocols' do
      importer.import_from_dir(export_dir)

      expect(imported_team.tags.pluck(:name)).to eq ['Exported tag']
      expect(imported_team.protocol_keywords.pluck(:name)).to eq ['Exported keyword']
      folders = imported_team.project_folders.index_by(&:name)
      expect(folders['Sub folder'].parent_folder_id).to eq folders['Parent folder'].id

      repo_protocol = imported_team.protocols.find_by(name: 'Repository protocol')
      expect(repo_protocol.protocol_keywords.pluck(:name)).to eq ['Exported keyword']
      expect(repo_protocol.steps.first.step_texts.first.text).to eq 'Repo step text'
    end

    it 'imports the project structure with tasks, steps and results' do
      importer.import_from_dir(export_dir)

      imported_project = imported_team.projects.find_by(name: 'Exported project')
      expect(imported_project.project_folder.name).to eq 'Sub folder'
      expect(imported_project.project_comments.pluck(:message)).to include 'Project comment'

      imported_experiment = imported_project.experiments.find_by(name: 'Exported experiment')
      tasks = imported_experiment.my_modules.index_by(&:name)
      expect(tasks.keys).to match_array ['Task A', 'Task B']
      expect(tasks['Task A'].tags.pluck(:name)).to eq ['Exported tag']
      expect(tasks['Task A'].task_comments.pluck(:message)).to eq ['Task comment']
      expect(tasks['Task A'].user_my_modules.count).to eq 1
      expect(tasks['Task A'].my_modules).to eq [tasks['Task B']]

      step = tasks['Task A'].protocol.steps.find_by(name: 'Task step')
      expect(step.step_comments.pluck(:message)).to eq ['Step comment']
      expect(step.step_texts.pluck(:text)).to eq ['Task step text']
      expect(step.checklists.first.checklist_items.pluck(:text)).to eq ['Checklist item']
      expect(step.tables.pluck(:name)).to eq ['Step table']
      expect(step.assets.first.file).to be_attached

      result = tasks['Task A'].results.find_by(name: 'Exported result')
      expect(result.result_comments.pluck(:message)).to eq ['Result comment']
      expect(result.result_texts.first.text).to include '<p>Image <img'
      expect(result.tables.pluck(:name)).to eq ['Result table']
      expect(result.assets.first.file).to be_attached

      imported_text = result.result_texts.first
      imported_tiny_mce_asset = imported_text.tiny_mce_assets.first
      expect(imported_tiny_mce_asset.image).to be_attached
      expect(imported_text.reload.text).to include("data-mce-token=\"#{Base62.encode(imported_tiny_mce_asset.id)}\"")
    end

    it 'remaps smart annotations to the imported records' do
      # bug: TeamImporter#update_annotation rewrites user tokens with an unanchored text.sub!("~ID]", ...), so when
      # the NEW id of a task encodes to the same string as the OLD id of a user, the user remap also rewrites the
      # task token. Keep the new ids far away from the exported ones so this example does not depend on the id
      # sequences (the order the specs run in).
      %w(projects experiments my_modules users).each do |table|
        ActiveRecord::Base.connection.execute("SELECT setval('#{table}_id_seq', 1000000)")
      end

      importer.import_from_dir(export_dir)

      imported_project = imported_team.projects.find_by(name: 'Exported project')
      imported_task = imported_project.experiments.first.my_modules.find_by(name: 'Task A')
      imported_user = User.find_by(email: "imported-#{user.email}")
      annotated = imported_project.project_comments.where.not(message: 'Project comment').first
      expect(annotated.message).to include("~tsk~#{imported_task.id.base62_encode}]")
      expect(annotated.message).to include("[@Exporter~#{imported_user.id.base62_encode}]")
    end

    it 'imports reports, inventories, label templates and activities' do
      importer.import_from_dir(export_dir)

      imported_project = imported_team.projects.find_by(name: 'Exported project')
      report = imported_project.reports.find_by(name: 'Exported report')
      expect(report.report_elements.count).to eq 2
      child = report.report_elements.find_by(type_of: :my_module)
      expect(child.parent.type_of).to eq 'experiment'
      expect(child.my_module.name).to eq 'Task A'

      imported_repository = imported_team.repositories.find_by(name: 'Exported inventory')
      row = imported_repository.repository_rows.find_by(name: 'Exported row')
      values = row.repository_cells.includes(:repository_column).index_by { |c| c.repository_column.name }
      expect(values['Text column'].value.data).to eq 'Cell text'
      expect(values['List column'].value.repository_list_item.data).to eq 'List item'
      expect(values['Status column'].value.repository_status_item.status).to eq 'Done'
      expect(values['Checklist column'].value.repository_checklist_items.pluck(:data)).to eq ['Check item']
      expect(values['Asset column'].value.asset.file).to be_attached
      snapshot = RepositorySnapshot.find_by(name: 'Exported snapshot', team: imported_team)
      expect(snapshot.parent_id).to eq imported_repository.id
      expect(snapshot.my_module.name).to eq 'Task A'
      expect(row.my_modules.pluck(:name)).to eq ['Task A']
      expect(RepositoryTableState.where(repository: imported_repository).count).to eq 1

      # Default (non-Fluics) templates are replaced by the exported ones, so no duplicates appear
      expect(imported_team.label_templates.where.not(type: 'FluicsLabelTemplate').pluck(:name))
        .to match_array(team.label_templates.where.not(type: 'FluicsLabelTemplate').pluck(:name))
      expect(imported_team.label_templates.find_by(name: 'Exported label').created_by.email)
        .to eq "imported-#{user.email}"
      expect(Activity.where(team: imported_team).count).to eq 2
      expect(Activity.where(team: imported_team, project: imported_project).count).to eq 1
    end
  end
end
