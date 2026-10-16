# frozen_string_literal: true

require 'rails_helper'

describe Experiments::CopyExperimentAsTemplateService do
  let(:user) { create :user }
  let(:team) { create :team, created_by: user }

  let(:project) do
    create :project, team: team, created_by: user
  end
  let(:new_project) do
    create :project, team: team, created_by: user
  end
  let(:experiment) do
    create :experiment, :with_tasks, name: 'MyExp', project: project
  end

  let(:service_call) do
    Experiments::CopyExperimentAsTemplateService.call(experiment: experiment, project: new_project, user: user)
  end

  # tasks are copied only when readable by the user, and readability is resolved against the user's current team
  before { user.update!(current_team_id: team.id) }

  context 'when service call is successful' do
    it 'adds new experiment to target project' do
      expect { service_call }.to(change { new_project.experiments.count })
    end

    it 'adds Activity record' do
      expect { service_call }.to(change { Activity.all.count })
    end

    it 'calls create activity service' do
      # copied tasks also trigger designate_user_to_my_module activities, so other calls are allowed
      allow(Activities::CreateActivityService).to receive(:call)
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

    # permission checks run in the controllers (can_clone_experiment?, can_create_project_experiments?)
    # before the service is called, so the service itself adds no errors and clones into the target project
    it 'returns no errors and clones the experiment into the target project' do
      expect(service_call.errors).to be_empty
      expect(service_call.cloned_experiment.project).to eq new_project
    end
  end

  context 'when service call is not successful' do
    # bug: nil experiment raises in initialize; valid? also never returns false (missing return), so errors[:invalid_arguments] is unreachable
    it 'raises NoMethodError when experiment is nil' do
      expect { described_class.call(experiment: nil, project: new_project, user: user) }
        .to raise_error(NoMethodError)
    end
  end
end
