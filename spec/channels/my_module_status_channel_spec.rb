# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MyModuleStatusChannel, type: :channel do
  let(:owner_user) { create :user }
  let(:team) { create :team, created_by: owner_user, skip_user_assignments: true }
  let(:owner_role) { UserRole.find_by(name: I18n.t('user_roles.predefined.owner')) }
  let!(:team_assignment) do
    create :user_assignment, user: owner_user, assignable: team, user_role: owner_role
  end
  let(:project) do
    create :project, team: team, created_by: owner_user, default_public_user_role_id: owner_role.id
  end
  let(:experiment) { create :experiment, project: project, created_by: owner_user }
  let(:status_flow) { create :my_module_status_flow }
  let(:my_module_status) { create :my_module_status, my_module_status_flow: status_flow }
  let(:my_module) do
    create :my_module, experiment: experiment, created_by: owner_user, my_module_status: my_module_status
  end
  let(:unassigned_user) { create :user }

  # Matches ApplicationCable::Connection#find_verified_user, which reads the
  # warden session.
  let(:warden) { instance_double('Warden::Proxy') }

  before do
    allow(warden).to receive(:user).and_return(current_user)
    # can_read_my_module? resolves permissions against the user's persisted
    # current team, which loading the task page always sets to the task's team.
    owner_user.update!(current_team_id: team.id)
    stub_connection current_user: current_user, env: { 'warden' => warden }
  end

  context 'when the user can read the task' do
    let(:current_user) { owner_user }

    it 'streams for the task' do
      subscribe(my_module_id: my_module.id)

      expect(subscription).to be_confirmed
      expect(subscription).to have_stream_for(my_module)
    end

    it 'transmits the current status state on sync' do
      subscribe(my_module_id: my_module.id)
      perform :sync

      expect(transmissions.last.deep_symbolize_keys).to include(
        my_module_status_id: my_module.my_module_status_id,
        status_changing: false,
        transition_failed: false
      )
    end
  end

  context 'when the user cannot read the task' do
    let(:current_user) { unassigned_user }

    it 'rejects the subscription' do
      subscribe(my_module_id: my_module.id)

      expect(subscription).to be_rejected
    end
  end

  context 'when the task does not exist' do
    let(:current_user) { owner_user }

    it 'rejects the subscription' do
      subscribe(my_module_id: -1)

      expect(subscription).to be_rejected
    end
  end
end
