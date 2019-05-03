# frozen_string_literal: true

require 'rails_helper'

describe Experiments::MoveToProjectService do
  let(:team) { create :team, :with_members }
  let(:project) do
    create :project, team: team, user_projects: []
  end
  let(:new_project) do
    create :project, team: team, user_projects: [user_project2]
  end
  let(:experiment) do
    create :experiment, :with_tasks, name: 'MyExp', project: project
  end
  let(:user) { create :user }
  let(:user_project2) { create :user_project, :normal_user, user: user }
  let(:service_call) do
    Experiments::MoveToProjectService.call(experiment_id: experiment.id,
                                    project_id: new_project.id,
                                    user_id: user.id)
  end

  context 'when call with valid params' do
    it 'unnasigns experiment from project' do
      service_call

      expect(project.experiments.pluck(:id)).to_not include(experiment.id)
    end

    it 'assigns experiment to new_project' do
      service_call

      expect(new_project.experiments.pluck(:id)).to include(experiment.id)
    end

    it 'copies tags to new project' do
      expect { service_call }.to(change { new_project.tags.count })
    end

    it 'leaves tags on an old project' do
      experiment # explicit call to create tags
      expect { service_call }.not_to(change { project.tags.count })
    end

    it 'sets new project tags to modules' do
      service_call
      new_tags = experiment.my_modules.map { |m| m.tags.map { |t| t } }.flatten
      tags_project_id = new_tags.map(&:project_id).uniq.first

      expect(tags_project_id).to be == new_project.id
    end

    it 'adds Activity record' do
      expect { service_call }.to(change { Activity.all.count })
    end

    it 'calls create activity service' do
      expect(Activities::CreateActivityService).to receive(:call)
        .with(hash_including(activity_type: :move_experiment))

      service_call
    end
  end

  context 'when call with invalid params' do
    it 'returns an error when can\'t find user and project' do
      allow(Project).to receive(:find).and_return(nil)
      allow(User).to receive(:find).and_return(nil)

      expect(service_call.errors).to have_key(:invalid_arguments)
    end

    it 'returns an error on validate' do
      FactoryBot.create :experiment, project: new_project, name: 'MyExp'
      expect(service_call.succeed?).to be_falsey
    end

    it 'returns an error on saving' do
      expect_any_instance_of(Experiments::MoveToProjectService)
        .to receive(:valid?)
        .and_return(true)
      FactoryBot.create :experiment, project: new_project, name: 'MyExp'

      expect(service_call.succeed?).to be_falsey
    end

    it 'rollbacks cloned tags after unsucessful save' do
      expect_any_instance_of(Experiments::MoveToProjectService)
        .to receive(:valid?)
        .and_return(true)
      FactoryBot.create :experiment, project: new_project, name: 'MyExp'
      experiment

      expect { service_call }.not_to(change { Tag.count })
    end

    it 'returns error if teams is not the same' do
      t = create :team, :with_members
      project.update(team: t)

      expect(service_call.errors).to have_key(:target_project_not_valid)
    end
  end
end
