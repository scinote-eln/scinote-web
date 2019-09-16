# frozen_string_literal: true

require 'rails_helper'

describe Experiment, type: :model do
  let(:experiment) { build :experiment }

  it 'is valid' do
    expect(experiment).to be_valid
  end

  it 'should be of class Experiment' do
    expect(subject.class).to eq Experiment
  end

  describe 'Database table' do
    it { should have_db_column :id }
    it { should have_db_column :name }
    it { should have_db_column :description }
    it { should have_db_column :project_id }
    it { should have_db_column :created_by_id }
    it { should have_db_column :last_modified_by_id }
    it { should have_db_column :archived }
    it { should have_db_column :archived_by_id }
    it { should have_db_column :archived_on }
    it { should have_db_column :restored_by_id }
    it { should have_db_column :restored_on }
    it { should have_db_column :created_at }
    it { should have_db_column :updated_at }
    it { should have_db_column :uuid }
  end

  describe 'Relations' do
    it { should belong_to(:project) }
    it { should belong_to(:created_by).class_name('User') }
    it { should belong_to(:last_modified_by).class_name('User') }
    it { should belong_to(:archived_by).class_name('User').optional }
    it { should belong_to(:restored_by).class_name('User').optional }
    it { should have_many :my_modules }
    it { should have_many :my_module_groups }
    it { should have_many :report_elements }
    it { should have_many :activities }
  end

  describe 'Should be a valid object' do
    let(:project) { create :project }
    it { should validate_presence_of :project }
    it { should validate_presence_of :created_by }
    it { should validate_presence_of :last_modified_by }
    it do
      should validate_length_of(:name)
        .is_at_least(Constants::NAME_MIN_LENGTH)
        .is_at_most(Constants::NAME_MAX_LENGTH)
    end

    it do
      should validate_length_of(:description)
        .is_at_most(Constants::TEXT_MAX_LENGTH)
    end

    it 'should have uniq name scoped on project' do
      create :experiment, name: 'experiment',
                          project: project,
                          created_by: project.created_by,
                          last_modified_by: project.created_by
      new_exp = build_stubbed :experiment, name: 'experiment',
                                           project: project,
                                           created_by: project.created_by,
                                           last_modified_by: project.created_by
      expect(new_exp).to_not be_valid
    end

    it 'should have uniq uuid scoped on project' do
      uuid = SecureRandom.uuid
      puts uuid
      create :experiment, name: 'experiment',
                          project: project,
                          created_by: project.created_by,
                          last_modified_by: project.created_by,
                          uuid: uuid
      new_exp = build_stubbed :experiment, name: 'new experiment',
                                           project: project,
                                           created_by: project.created_by,
                                           last_modified_by: project.created_by,
                                           uuid: uuid
      expect(new_exp).to_not be_valid
    end
  end

  describe '.update_canvas' do
    let(:experiment) { create :experiment, :with_tasks }
    let(:user) { experiment.created_by }

    context 'when creating tasks' do
      let(:to_add) do
        [{ id: 'n0', name: 'new task name', x: 50, y: 50 }]
      end
      let(:function_call) do
        experiment.update_canvas([], to_add, [], [], [], [], [], [], user)
      end

      it 'calls create activity for creating tasks' do
        expect(Activities::CreateActivityService)
          .to(receive(:call)
                .with(hash_including(activity_type: :create_module)))

        function_call
      end

      it 'adds activity in DB' do
        expect { function_call }.to(change { Activity.all.count })
      end
    end

    context 'when cloning tasks' do
      let(:to_add) do
        experiment
          .my_modules
          .map.with_index do |t, i|
            { id: 'n' + i.to_s,
              name: t.name + '_new',
              x: 50,
              y: 50 + i }
          end
      end
      let(:to_clone) do
        experiment
          .my_modules
          .map.with_index { |t, i| { 'n' + i.to_s => t.id } }.reduce({}, :merge)
      end
      let(:function_call) do
        experiment.update_canvas([], to_add, [], [], [], to_clone, [], [], user)
      end

      it 'calls create activity for cloning tasks' do
        expect(Activities::CreateActivityService)
          .to(receive(:call)
                .with(hash_including(activity_type:
                                       :clone_module))).exactly(3).times

        function_call
      end

      it 'creats 3 new activities in DB' do
        expect { function_call }.to change { Activity.all.count }.by(3)
      end
    end

    context 'when renaming tasks' do
      let(:to_rename) do
        experiment
          .my_modules
          .map { |t| { t.id => t.name + '_new' } }.reduce({}, :merge)
      end

      let(:function_call) do
        experiment.update_canvas([], [], to_rename, [], [], [], [], [], user)
      end

      it 'calls create activity for renaming my_moudles' do
        expect(Activities::CreateActivityService)
          .to(receive(:call)
                .with(hash_including(activity_type:
                                       :rename_task))).exactly(3).times

        function_call
      end

      it 'creats 3 new activities in DB' do
        expect { function_call }.to change { Activity.all.count }.by(3)
      end
    end

    context 'when archiving tasks' do
      let(:to_archive) { experiment.my_modules.pluck(:id) }

      let(:function_call) do
        experiment.update_canvas(to_archive, [], [], [], [], [], [], [], user)
      end

      it 'calls create activity for archiving tasks' do
        expect(Activities::CreateActivityService)
          .to(receive(:call)
                .with(hash_including(activity_type:
                                       :archive_module))).exactly(3).times

        function_call
      end

      it 'creats 3 new activities in DB' do
        expect { function_call }.to change { Activity.all.count }.by(3)
      end
    end

    context 'when moving tasks to another experiment' do
      let(:new_experiment) { create :experiment, project: experiment.project }
      let(:to_move) do
        experiment
          .my_modules
          .map { |t| { t.id => new_experiment.id } }.reduce({}, :merge)
      end
      let(:function_call) do
        experiment.update_canvas([], [], [], to_move, [], [], [], [], user)
      end

      it 'calls create activity for moving tasks to another experiment' do
        expect(Activities::CreateActivityService)
          .to(receive(:call)
                .with(hash_including(activity_type:
                                       :move_task))).exactly(3).times

        function_call
      end

      it 'creats 3 new activities in DB' do
        expect { function_call }.to change { Activity.all.count }.by(3)
      end
    end
  end
end
