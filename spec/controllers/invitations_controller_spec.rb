# frozen_string_literal: true

require 'rails_helper'

describe Users::InvitationsController, type: :controller do
  login_user

  let(:user) { subject.current_user }
  let!(:team) { create :team, created_by: user }
  let!(:user_team) { create :user_team, :admin, user: user, team: team }

  describe 'POST invite_users' do
    let(:invited_user) { create :user }
    let(:team) { create :team }
    let(:params) do
      {
        teamId: team.id,
        emails: [invited_user.email],
        role: 'guest'
      }
    end
    let(:action) { post :invite_users, params: params, format: :json }

    context 'when inviting existing user not in the team' do
      it 'calls create activity for inviting user' do
        expect(Activities::CreateActivityService)
          .to(receive(:call)
                .with(hash_including(activity_type: :invite_user_to_team)))

        action
      end

      it 'adds activity in DB' do
        expect { action }
          .to(change { Activity.count })
      end

      it 'adds user_team record in DB' do
        expect { action }
          .to(change { UserTeam.count })
      end
    end
  end
end
