# frozen_string_literal: true

require 'rails_helper'

describe Experiments::CopyExperimentAsTemplateService do
  let(:user) { create :user }
  let(:team) { create :team, created_by: user, skip_user_assignments: true }
  let(:owner_role) { UserRole.find_by(name: I18n.t('user_roles.predefined.owner')) }
  let!(:team_assignment) { create :user_assignment, user: user, assignable: team, user_role: owner_role }
  let(:project) { create :project, team: team, created_by: user, default_public_user_role_id: owner_role.id }
  let(:new_project) { create :project, team: team, created_by: user, default_public_user_role_id: owner_role.id }
  let(:experiment) { create :experiment, name: 'MyExp', project: project, created_by: user }
  let!(:grouped_my_module) { create :my_module, experiment: experiment, created_by: user }
  let!(:single_my_module) { create :my_module, experiment: experiment, created_by: user, my_module_group: nil }

  let(:service_call) do
    described_class.call(experiment: experiment, project: new_project, user: user)
  end

  around do |example|
    queue_adapter = ActiveJob::Base.queue_adapter
    ActiveJob::Base.queue_adapter = :test
    example.run
  ensure
    ActiveJob::Base.queue_adapter = queue_adapter
  end

  before do
    user.update!(current_team_id: team.id)
  end

  context 'when service call is successful' do
    it 'adds new experiment to target project' do
      expect { service_call }.to(change { new_project.experiments.count })
    end

    it 'adds Activity record' do
      expect { service_call }.to(change { Activity.all.count })
    end

    it 'calls create activity service' do
      allow(Activities::CreateActivityService).to receive(:call).and_call_original
      expect(Activities::CreateActivityService).to receive(:call)
        .with(hash_including(activity_type: :clone_experiment))

      service_call
    end

    it 'copies all tasks to new experiment' do
      expect(service_call.cloned_experiment.my_modules.count)
        .to be == experiment.my_modules.count
    end

    it 'copies all task groups to new experiment' do
      expect(service_call.cloned_experiment.my_module_groups.count)
        .to be == experiment.my_module_groups.count
    end
  end

  context 'when service call is not successful' do
    it 'returns an error when project is missing' do
      service = described_class.call(experiment: experiment, project: nil, user: user)

      expect(service.errors).to have_key(:invalid_arguments)
    end
  end

  describe 'copying results' do
    def expect_copy_content_jobs(copy_results:)
      [grouped_my_module, single_my_module].each do |my_module|
        expect(MyModules::CopyContentJob).to have_been_enqueued
          .with(user.id, my_module.id, anything, skip_activities: true, copy_results: copy_results)
      end
    end

    context 'when copy_results is not set' do
      it 'copies tasks without results' do
        expect(service_call.succeed?).to be true
        expect_copy_content_jobs(copy_results: false)
      end
    end

    context 'when copy_results is true' do
      it 'copies tasks with results' do
        service = described_class.call(experiment: experiment, project: new_project, user: user, copy_results: true)

        expect(service.succeed?).to be true
        expect_copy_content_jobs(copy_results: true)
      end
    end
  end
end
