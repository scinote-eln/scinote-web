# frozen_string_literal: true

require 'rails_helper'

describe TeamImporter do

  def check_module(json_module, db_module)
    it { expect(my_module.dig('my_module', 'name')).to be_a(String) }
  end
  describe '#import_template_experiment_from_dir' do
    context 'successful import of all different elements with given json' do

      TEMPLATE_DIR = "#{Rails.root}/spec/services/model_importers/" \
                     "test_experiment_data"
      before :all do
        time = Time.new(2015, 8, 1, 14, 35, 0)
        create :user, email: Faker::Internet.email
        @user = create :user
        @team = create :team
        create :project, name: 'Project 1', visibility: 1, team: @team,
          archived: false, created_at: time

        @project = create :project, name: 'Project', visibility: 1, team: @team,
          archived: false, created_at: time

        @json =         @team_importer =  TeamImporter.new
        @exp = @team_importer
          .import_template_experiment_from_dir(TEMPLATE_DIR, 2, 2)
      end

      describe 'Experiment variables' do
        it { expect(@exp.id).to eq 1 }
        it { expect(@exp.project.id).to eq 2 }
        it { expect(@exp.name).to eq 'Experiment export' }
        it { expect(@exp.description).to eq 'My description' }

        it { expect(@exp.created_at).to eq '2019-01-21T13:27:53.342Z' }
        it { expect(@exp.created_by.id).to eq 2 }
        it { expect(@exp.last_modified_by.id).to eq 2 }

        it { expect(@exp.archived).to eq false }
        it { expect(@exp.archived_by_id).to be_nil }
        it { expect(@exp.archived_on).to be_nil }

        it { expect(@exp.restored_by_id).to be_nil }
        it { expect(@exp.restored_on).to be_nil }

        it { expect(@exp.workflowimg_updated_at).to eq '2019-01-21T13:31:04.682Z' }
        it { expect(@exp.workflowimg_file_size).to eq 4581 }
      end

      describe 'Module groups' do
        # Module groups
        it { expect(@exp.my_module_groups.count).to eq 2 }
        it { expect(@exp.my_module_groups.pluck(:created_by_id)).to all eq 2 }
        it { expect(@exp.my_module_groups.pluck(:created_at)).to(
             match_array(['2019-01-21T13:32:46.449Z'.to_time,
                          '2019-01-21T13:32:46.460Z'.to_time])) }
        it { expect(@exp.my_module_groups.pluck(:updated_at)).to(
             match_array(['2019-01-21T13:32:46.449Z'.to_time,
                          '2019-01-21T13:32:46.460Z'.to_time])) }
        it { expect(@exp.modules_without_group.count).to(
             eq 1) }
        it { expect(@exp.my_modules.where(my_module_group: nil).count).to(
             eq 2) }
        it { expect(@exp.archived_modules.count).to(
             eq 1) }
      end

      describe 'Modules' do
        @json = JSON.parse(File.read("#{TEMPLATE_DIR}" \
                                     "/experiment_export.json"))
        @json['my_modules'].each do |my_module|
          check_module(my_module, '')
        end
      end
    end
  end
end
