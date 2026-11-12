# frozen_string_literal: true

require 'rails_helper'

describe UserAssignmentsHelper, type: :helper do
  let(:user) { create :user }
  let(:other_user) { create :user, full_name: 'Jane <b>Doe</b>' }
  let(:team) { create :team, created_by: user }
  let(:owner_role) { UserRole.find_predefined_owner_role }
  let(:project) { create :project, team: team, created_by: user }
  let(:experiment) { create :experiment, project: project, user: user }

  before do
    without_partial_double_verification { allow(helper).to receive(:current_user).and_return(user) }
  end

  describe '#current_assignee_name' do
    it 'appends the (you) marker for the current user' do
      expect(helper.current_assignee_name(user)).to eq "#{user.name} (you)"
    end

    it 'returns the HTML escaped name of another user' do
      expect(helper.current_assignee_name(other_user)).to eq 'Jane &lt;b&gt;Doe&lt;/b&gt;'
    end
  end

  describe '#user_assignment_resource_role_name' do
    before do
      create_user_assignment(project, owner_role, other_user, user)
      create_user_assignment(experiment, owner_role, other_user, user)
    end

    it 'returns an empty string for a project without inherit marker' do
      expect(helper.user_assignment_resource_role_name(other_user, project)).to eq ''
    end

    it 'returns the project tooltip for a project with the inherit marker' do
      expect(helper.user_assignment_resource_role_name(other_user, project, '_inherit'))
        .to eq 'This role was inherited from the project.'
    end

    it 'returns the experiment tooltip for a manually assigned experiment role' do
      experiment.user_assignments.find_by(user: other_user).update!(assigned: :manually)

      expect(helper.user_assignment_resource_role_name(other_user, experiment))
        .to eq 'This role was set on this experiment.'
    end

    it 'walks up to the parent when the role was assigned automatically' do
      experiment.user_assignments.find_by(user: other_user).update!(assigned: :automatically)

      expect(helper.user_assignment_resource_role_name(other_user, experiment))
        .to eq 'This role was inherited from the project.'
    end
  end
end
