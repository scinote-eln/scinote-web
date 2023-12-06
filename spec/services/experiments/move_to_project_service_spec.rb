# frozen_string_literal: true

require 'rails_helper'

describe Experiments::MoveToProjectService do
  let(:user) { create :user }
  let(:team) { create :team, :change_user_team, created_by: user }
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
    Experiments::MoveToProjectService.call(experiment_id: experiment.id,
                                           project_id: new_project.id,
                                           user_id: user.id)
  end

  let(:service_call_invalid_user) do
    Experiments::MoveToProjectService.call(experiment_id: experiment.id,
                                           project_id: nil,
                                           user_id: nil)
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
      experiment.reload
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
      expect(service_call_invalid_user.errors).to have_key(:invalid_arguments)
    end

    it 'returns an error on validate' do
      allow_any_instance_of(Experiment).to(receive(:movable_projects).and_return([]))

      expect(service_call.succeed?).to be_falsey
    end

    it 'returns an error on saving' do
      experiment.name = Faker::Lorem.characters(number: 300)
      experiment.save(validate: false)

      expect(service_call.succeed?).to be_falsey
    end

    it 'rollbacks cloned tags after unsucessful save' do
      experiment.name = Faker::Lorem.characters(number: 300)
      experiment.save(validate: false)

      expect { service_call }.not_to(change { Tag.count })
    end

    it 'returns error if teams is not the same' do
      t = create :team
      project.update(team: t)

      expect(service_call.errors).to have_key(:target_project_not_valid)
    end
  end
end
