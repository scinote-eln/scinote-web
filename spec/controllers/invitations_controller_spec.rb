# frozen_string_literal: true

require 'rails_helper'

describe Users::InvitationsController, type: :controller do
  login_user

  include_context 'reference_project_structure'

  describe 'POST invite_users' do
    let(:invited_user) { create :user }
    let(:params) do
      {
        team_ids: [team.id],
        emails: [invited_user.email],
        role_id: viewer_role.id
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

      it 'adds user team assignment record in DB' do
        expect { action }
          .to(change { UserAssignment.count })
      end
    end
  end
end
