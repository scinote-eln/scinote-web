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
      let(:to_add) { [{ id: 'n0', name: 'new task name', x: 50, y: 50 }] }
      let(:function_call) { experiment.update_canvas([], to_add, [], {}, [], [], [], {}, user) }

      it 'calls create activity for creating tasks' do
        expect(Activities::CreateActivityService)
          .to(receive(:call)
                .with(hash_including(activity_type: :create_module)))
        expect(Activities::CreateActivityService)
          .to(receive(:call)
                .with(hash_including(activity_type: :designate_user_to_my_module)))
        function_call
      end

      it 'adds activity in DB' do
        expect { function_call }.to(change { Activity.all.count })
      end

      context 'when moving existing one and creating new one on the same position' do
        let(:first_task) { experiment.my_modules.first }
        let(:to_add) { [{ id: 'n0', name: 'new task name', x: 0, y: 0 }] }
        let(:function_call) { experiment.update_canvas([], to_add, [], {}, [], [], [], positions, user) }
        let(:positions) do
          Hash[first_task.id.to_s,
               { x: first_task.x + 1, y: first_task.y + 1 }, 'n0', { x: first_task.x, y: first_task.y }]
        end

        before do
          first_task.update(x: 0, y: 0)
        end

        it 'returns true' do
          expect(function_call).to be_truthy
        end
      end

      context 'when creating new one on position of "toBeArchived" task' do
        let(:first_task) { experiment.my_modules.first }
        let(:to_add) { [{ id: 'n0', name: 'new task name', x: 0, y: 0 }] }
        let(:positions) { Hash['n0', { x: first_task.x, y: first_task.y }] }
        let(:to_archive) { [first_task.id] }
        let(:function_call) { experiment.update_canvas(to_archive, to_add, [], {}, [], [], [], positions, user) }

        before do
          first_task.update(x: 0, y: 0)
        end

        it 'returns true' do
          expect(function_call).to be_truthy
        end
      end

      context 'when creating new one on position of "toBeMoved" task' do
        let(:first_task) { experiment.my_modules.first }
        let(:to_add) { [{ id: 'n0', name: 'new task name', x: 0, y: 0 }] }
        let(:positions) { Hash['n0', { x: first_task.x, y: first_task.y }] }
        let(:to_move) { Hash[first_task.id, second_experiment.id] }
        let(:second_experiment) { create :experiment, project: experiment.project }
        let(:function_call) { experiment.update_canvas([], to_add, [], to_move, [], [], [], positions, user) }

        before do
          first_task.update(x: 0, y: 0)
        end

        it 'returns true' do
          expect(function_call).to be_truthy
        end
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
        experiment.update_canvas([], to_add, [], {}, [], to_clone, [], {}, user)
      end

      it 'calls create activity for cloning tasks' do
        expect(Activities::CreateActivityService)
          .to(receive(:call)
                .with(hash_including(activity_type:
                                       :clone_module))).exactly(3).times
        expect(Activities::CreateActivityService)
          .to(receive(:call)
                .with(hash_including(activity_type:
                                       :designate_user_to_my_module))).exactly(6).times
        function_call
      end

      it 'creats 9 new activities in DB (6 for assigning user, 3 for cloning module)' do
        expect { function_call }.to change { Activity.all.count }.by(9)
      end
    end

    context 'when renaming tasks' do
      let(:to_rename) do
        experiment
          .my_modules
          .map { |t| { t.id => t.name + '_new' } }.reduce({}, :merge)
      end

      let(:function_call) do
        experiment.update_canvas([], [], to_rename, {}, [], [], [], {}, user)
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
        experiment.update_canvas(to_archive, [], [], {}, [], [], [], {}, user)
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
        experiment.update_canvas([], [], [], to_move, [], [], [], {}, user)
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

    context 'when moving new task (not saved to DB yet)' do
      let(:first_task) { experiment.my_modules.first }
      let(:second_experiment) { create :experiment, project: experiment.project }
      let(:to_add) { [{ id: 'n0', name: 'new task name', x: 0, y: 0 }] }
      let(:to_move) { Hash['n0', second_experiment.id] }
      let(:function_call) { experiment.update_canvas([], to_add, [], to_move, [], [], [], {}, user) }

      it 'returns true' do
        expect(function_call).to be_truthy
      end

      it 'assigns task to new experiment' do
        expect { function_call }.to change { second_experiment.my_modules.count }.by(1)
      end
    end
  end
end
