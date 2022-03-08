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
        @team = create :team
        create :project, name: 'Temp project', visibility: 1,
          team: @team, archived: false, created_at: time

        @project = create :project, name: 'Project', visibility: 1, team: @team,
          archived: false, created_at: time

        # Reassign if multiple tests are run
        PROJECT_ID = @project.id
        USER_ID = @user.id

        @team_importer = TeamImporter.new
        @exp = @team_importer.import_experiment_template_from_dir(TEMPLATE_DIR,
                                                                  PROJECT_ID,
                                                                  USER_ID)
        Experiments::GenerateWorkflowImageService.call(experiment_id: @exp.id)
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

        it { expect(@exp.workflowimg.exists?).to eq(true) }
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
        it { expect(@exp.archived_modules.count).to eq 1 }
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
            if json_module['my_module_group_id'].nil?
              expect(db_module.my_module_group_id).to be_nil
            end

            expect(db_module.nr_of_assigned_samples).to be_zero

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
            expect(db_protocol.added_by_id).to eq(
              json_protocol.dig('added_by_id')
            )
            expect(db_protocol.archived_by_id).to be_nil
            expect(db_protocol.archived_on).to be_nil
            expect(db_protocol.restored_by_id).to be_nil
            expect(db_protocol.restored_on).to be_nil
            expect(db_protocol.authors).to eq json_protocol['authors']
            expect(db_protocol.parent_id).to eq json_protocol['parent_id']
            expect(db_protocol.parent_updated_at).to eq(
              json_protocol['parent_updated_at']
            )
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
              expect(db_step.description).to eq json_step_obj['description']
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

              # Checklists
              expect(db_step.checklists.count).to eq(
                json_step['checklists'].count
              )
              json_step['checklists'].each do |checklist|
                json_checklist = checklist['checklist']
                json_items = checklist['checklist_items']
                db_checklist = db_step.checklists.find_by(
                  name: json_checklist['name']
                )

                # Checklist object
                expect(db_checklist.created_at).to eq(
                  json_checklist['created_at'].to_time
                )
                expect(db_checklist.updated_at).to eq(
                  json_checklist['updated_at'].to_time
                )
                expect(db_checklist.created_by_id).to eq USER_ID
                expect(db_checklist.last_modified_by_id).to eq USER_ID

                expect(db_checklist.checklist_items.count).to eq(
                  json_items.count
                )

                # Checklist items
                json_items.each do |json_item|
                  db_item = db_checklist.checklist_items.find_by(
                    text: json_item['text']
                  )
                  expect(db_item.checked).to eq(json_item['checked'])
                  expect(db_item.position).to eq(json_item['position'])
                  expect(db_item.created_at).to eq(
                    json_item['created_at'].to_time
                  )
                  expect(db_item.updated_at).to eq(
                    json_item['updated_at'].to_time
                  )
                  expect(db_item.created_by_id).to eq USER_ID
                  expect(db_item.last_modified_by_id).to eq USER_ID
                end
              end

              # Step assets
              expect(db_step.assets.count).to eq(
                json_step['assets'].count
              )

              expect(db_step.step_assets.count).to eq(
                json_step['step_assets'].count
              )

              json_step['assets'].each do |json_asset|
                db_asset = db_step.assets.find_by(
                  file_file_name: json_asset['file_file_name']
                )

                # Basic fields
                expect(db_asset.created_at).to eq(
                  json_asset['created_at'].to_time
                )
                expect(db_asset.created_by_id).to eq USER_ID
                expect(db_asset.last_modified_by_id).to eq USER_ID
                expect(db_asset.team_id). to eq @team.id

                # Other fields
                expect(db_asset.estimated_size).to eq(
                  json_asset['estimated_size']
                )
                expect(db_asset.file_content_type).to eq(
                  json_asset['file_content_type']
                )
                expect(db_asset.file_file_size).to eq(
                  json_asset['file_file_size']
                )
                expect(db_asset.file_updated_at).to be_within(10.seconds)
                  .of(Time.now)
                expect(db_asset.lock).to eq(
                  json_asset['lock']
                )
                expect(db_asset.lock_ttl).to eq(
                  json_asset['lock_ttl']
                )
                expect(db_asset.version).to eq(
                  json_asset['version']
                )
              end

              # Tables
              expect(db_step.step_tables.count).to eq(
                json_step['step_tables'].count
              )
              expect(db_step.tables.count).to eq(
                json_step['tables'].count
              )

              json_step['tables'].each do |json_table|
                db_table = db_step.tables.find_by(
                  contents: Base64.decode64(json_table['contents'])
                )

                # Basic fields
                expect(db_table.created_at).to eq(
                  json_table['created_at'].to_time
                )
                expect(db_table.updated_at).to eq(
                  json_table['updated_at'].to_time
                )
                expect(db_table.created_by_id).to eq USER_ID
                expect(db_table.last_modified_by_id).to eq USER_ID
                expect(db_table.team_id). to eq @team.id

                # Other fields
                expect(db_table.name).to eq(json_table['name'])
                expect(db_table.data_vector).to eq(
                  Base64.decode64(json_table['data_vector'])
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
            unless my_module['user_my_modules'].empty?
              expect(db_module.user_my_modules.first.user_id).to eq USER_ID
            end
          end
        end
      end
    end
  end
end
