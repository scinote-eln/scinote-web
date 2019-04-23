# frozen_string_literal: true

require 'rails_helper'

describe Users::Settings::UserTeamsController, type: :controller do
  login_user

  let(:user) { subject.current_user }
  let(:team) { create :team, created_by: user }
  let!(:user_team) { create :user_team, :admin, user: user, team: team }
  let(:another_user) { create :user }
  let!(:another_user_team) do
    create :user_team, :normal_user, user: another_user, team: team
  end
  describe 'DELETE destroy' do
    let(:params) do
      {
        id: another_user_team.id
      }
    end
    let(:action) { delete :destroy, params: params, format: :json }

    context 'when inviting existing user not in the team' do
      it 'calls create activity for inviting user' do
        expect(Activities::CreateActivityService)
          .to(receive(:call)
                .with(hash_including(activity_type: :remove_user_from_team)))

        action
      end

      it 'adds activity in DB' do
        expect { action }
          .to(change { Activity.count })
      end

      it 'remove user_team record from DB' do
        expect { action }
          .to(change { UserTeam.count })
      end
    end

    context 'when user leaving team by himself' do
      it 'calls create activity for user leaving' do
        params_leave = { id: another_user_team.id, leave: true }
        expect(Activities::CreateActivityService)
          .to(receive(:call)
                .with(hash_including(activity_type: :user_leave_team)))

        delete :destroy, params: params_leave, format: :json
      end

      it 'adds activity in DB' do
        params_leave = { id: another_user_team.id, leave: true }
        expect { delete :destroy, params: params_leave, format: :json }
          .to(change { Activity.count })
      end
    end
  end

  describe 'PUT update' do
    let(:params) do
      {
        id: another_user_team.id,
        user_team: {
          role: 'admin'
        }
      }
    end
    let(:action) { put :update, params: params, format: :json }

    context 'when updating user role in the team' do
      it 'calls create activity for updating role' do
        expect(Activities::CreateActivityService)
          .to(receive(:call)
                .with(hash_including(activity_type:
                                       :change_users_role_on_team)))

        action
      end

      it 'adds activity in DB' do
        expect { action }
          .to(change { Activity.count })
      end
    end
  end
end
