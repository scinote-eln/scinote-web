# frozen_string_literal: true

require 'rails_helper'

describe Experiments::CopyExperimentAsTemplateService do
  let(:team) { create :team, :with_members }
  let(:user_project) { create :user_project, :normal_user, user: user }

  let(:project) do
    create :project, team: team
  end
  let(:new_project) do
    create :project, team: team, user_projects: [user_project]
  end
  let(:experiment) do
    create :experiment, :with_tasks, name: 'MyExp', project: project
  end
  let(:user) { create :user }
  let(:service_call) do
    Experiments::CopyExperimentAsTemplateService
      .call(experiment_id: experiment.id,
           project_id: new_project.id,
           user_id: user.id)
  end

  context 'when service call is successful' do
    it 'adds new experiment to target project' do
      expect { service_call }.to(change { new_project.experiments.count })
    end

    it 'adds Activity record' do
      expect { service_call }.to(change { Activity.all.count })
    end

    it 'calls create activity service' do
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
    it 'returns an error when can\'t find experiment' do
      allow(Experiment).to receive(:find).and_return(nil)

      expect(service_call.errors).to have_key(:invalid_arguments)
    end

    it 'returns error when user don\'t have permissions' do
      expect_any_instance_of(Experiment)
        .to receive(:projects_with_role_above_user).and_return([])

      expect(service_call.errors).not_to be_empty
    end
  end
end
