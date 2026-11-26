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
  describe 'extended behaviour' do
    let(:delayed) { instance_double(User, deliver_invitation: true) }

    before do
      @request.env['devise.mapping'] = Devise.mappings[:user]
      allow_any_instance_of(User).to receive(:delay).and_return(delayed)
      Rails.configuration.x.enable_recaptcha = false
    end

    after { Rails.configuration.x.enable_recaptcha = false }

    def results
      assigns(:invite_results)
    end

    describe 'unsupported devise actions' do
      it 'raises NotImplementedError for new and create' do
        expect { get :new }.to raise_error(NotImplementedError)
        expect { post :create }.to raise_error(NotImplementedError)
      end
    end

    describe 'POST invite_users' do
      def invite(params)
        post :invite_users, params: params, format: :json
      end

      it 'creates and invites a new user to the team' do
        expect { invite(team_ids: [team.id], emails: [' New.Person@Example.com '], role_id: viewer_role.id) }
          .to change(User, :count).by(1)
          .and change { Activity.where(type_of: :invite_user_to_team).count }.by(1)
        created = User.find_by(email: 'new.person@example.com')
        expect(created.invited_by).to eq user
        expect(created.initials).to eq 'NE'
        expect(team.user_assignments.find_by(user: created).user_role).to eq viewer_role
        expect(results.first).to include(status: :user_created_invited_to_team, team_name: team.name)
        expect(delayed).to have_received(:deliver_invitation)
      end

      it 'creates a user without teams when no team is given' do
        expect { invite(emails: ['solo@example.com']) }.to change(User, :count).by(1)
        expect(results.first[:status]).to eq :user_created
        expect(Activity.where(type_of: :invite_user_to_team)).to be_empty
      end

      it 'rejects invalid emails' do
        expect { invite(team_ids: [team.id], emails: ['not-an-email']) }.not_to change(User, :count)
        expect(results.first[:status]).to eq :user_invalid
      end

      it 'reports existing users already in the team' do
        existing = create :user
        create_user_assignment(team, normal_user_role, existing)
        expect { invite(team_ids: [team.id], emails: [existing.email]) }.not_to change(UserAssignment, :count)
        expect(results.first[:status]).to eq :user_exists_and_in_team
      end

      it 'invites existing confirmed users to the team' do
        existing = create :user, confirmed_at: Time.zone.now
        invite(team_ids: [team.id], emails: [existing.email])
        expect(results.first[:status]).to eq :user_exists_invited_to_team
        expect(team.user_assignments.exists?(user: existing)).to be true
      end

      it 'marks existing unconfirmed users when invited to the team' do
        existing = create :user, confirmed_at: nil
        invite(team_ids: [team.id], emails: [existing.email])
        expect(results.first[:status]).to eq :user_exists_unconfirmed_invited_to_team
      end

      it 'reports existing users when no team is given' do
        existing = create :user
        invite(emails: [existing.email])
        expect(results.first[:status]).to eq :user_exists
      end

      it 'limits the number of invited emails' do
        stub_const('Constants::INVITE_USERS_LIMIT', 1)
        expect { invite(emails: %w(a1@example.com a2@example.com)) }.to change(User, :count).by(1)
        expect(assigns(:too_many_emails)).to be true
        expect(results.length).to eq 1
      end

      it 'is forbidden without emails' do
        invite(team_ids: [team.id])
        expect(response).to have_http_status(:forbidden)
      end

      it 'is forbidden for teams the user cannot manage' do
        team_assignment.update!(user_role: viewer_role)
        expect { invite(team_ids: [team.id], emails: ['x@example.com']) }.not_to change(User, :count)
        expect(response).to have_http_status(:forbidden)
      end

      it 'requires the captcha when enabled' do
        Rails.configuration.x.enable_recaptcha = true
        allow(controller).to receive(:verify_recaptcha).and_return(false)
        expect { invite(team_ids: [team.id], emails: ['x@example.com']) }.not_to change(User, :count)
        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)['recaptcha_error']).to eq I18n.t('invite_users.errors.recaptcha')
      end
    end

    describe 'GET invitable_teams' do
      it 'lists teams where the user can manage users' do
        get :invitable_teams, format: :json
        expect(JSON.parse(response.body)).to include('value' => team.id, 'label' => team.name)
      end

      it 'filters by query' do
        get :invitable_teams, params: { query: 'zzz-no-team' }, format: :json
        expect(JSON.parse(response.body)).to eq []
      end

      it 'excludes teams without user management permission' do
        team_assignment.update!(user_role: viewer_role)
        get :invitable_teams, format: :json
        expect(JSON.parse(response.body)).to eq []
      end
    end

    describe 'PUT update (accepting an invitation)' do
      let!(:invited) do
        User.invite!(full_name: 'Invitee', email: 'invitee@example.com', initials: 'IN', skip_invitation: true)
      end
      let(:accept_params) do
        { user: { invitation_token: invited.raw_invitation_token, full_name: 'Invitee Person',
                  password: 'Passw0rd!Passw0rd', password_confirmation: 'Passw0rd!Passw0rd' } }
      end

      around do |example|
        original = Rails.configuration.x.new_team_on_signup
        example.run
        Rails.configuration.x.new_team_on_signup = original
      end

      before do
        allow_any_instance_of(Team).to receive(:generate_template_project)
        sign_out :user
      end

      it 'accepts the invitation without creating a team' do
        Rails.configuration.x.new_team_on_signup = false
        put :update, params: accept_params
        expect(invited.reload.invitation_accepted_at).to be_present
        expect(invited.full_name).to eq 'Invitee Person'
      end

      it 'accepts the invitation and creates the team of the new user' do
        Rails.configuration.x.new_team_on_signup = true
        expect { put :update, params: accept_params.merge(team: { name: 'Invitee team' }) }
          .to change(Team, :count).by(1)
        expect(Team.find_by(name: 'Invitee team').created_by).to eq invited
        expect(invited.reload.invitation_accepted_at).to be_present
      end

      it 'does not accept the invitation when the team name is invalid' do
        Rails.configuration.x.new_team_on_signup = true
        expect { put :update, params: accept_params.merge(team: { name: '' }) }.not_to change(Team, :count)
        expect(invited.reload.invitation_accepted_at).to be_nil
      end

      it 're-renders edit when the captcha fails' do
        Rails.configuration.x.new_team_on_signup = false
        Rails.configuration.x.enable_recaptcha = true
        allow(controller).to receive(:verify_recaptcha).and_return(false)
        put :update, params: accept_params
        expect(response).to render_template(:edit)
        expect(invited.reload.invitation_accepted_at).to be_nil
      end
    end
  end
end
