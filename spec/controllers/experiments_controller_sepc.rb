# frozen_string_literal: true

require 'rails_helper'

describe ExperimentsController, type: :controller do
  login_user

  describe '#update' do
    let!(:user) { controller.current_user }
    let!(:team) { create :team, created_by: user, users: [user] }
    let!(:project) { create :project, team: team }
    let!(:user_project) do
      create :user_project, :owner, user: user, project: project
    end
    let(:experiment) { create :experiment, project: project }

    context 'when editing experiment' do
      let(:params) do
        {
          id: experiment.id,
          experiment: { title: 'new_title' }
        }
      end

      it 'calls create activity for editing experiment' do
        expect(Activities::CreateActivityService)
          .to(receive(:call)
                .with(hash_including(activity_type: :edit_experiment)))

        put :update, params: params
      end
    end

    context 'when archiving experiment' do
      let(:archived_experiment) do
        create :experiment,
               archived: true,
               archived_by: (create :user),
               archived_on: Time.now,
               project: project
      end

      let(:archived_params) do
        {
          id: archived_experiment.id,
          experiment: { archived: false }
        }
      end

      it 'calls create activity for unarchiving experiment' do
        expect(Activities::CreateActivityService)
          .to(receive(:call)
            .with(hash_including(activity_type: :restore_experiment)))

        put :update, params: archived_params
      end
    end
  end
end
