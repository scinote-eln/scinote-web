# frozen_string_literal: true

require 'rails_helper'

describe AccessPermissions::FormsController, type: :controller do
  login_user

  let!(:user) { subject.current_user }
  let!(:team) { create :team, created_by: user }
  let!(:object) { create :form, team: team, created_by: user }
  let!(:owner_role) { UserRole.find_by(name: I18n.t('user_roles.predefined.owner')) }
  let!(:normal_user_role) { create :normal_user_role }
  let!(:technician_role) { create :technician_role }
  let!(:normal_user) { create :user, confirmed_at: Time.zone.now }

  before do
    create_user_assignment(team, owner_role, user)
    create_user_assignment(team, normal_user_role, normal_user)
  end

  include_context 'reference_access_controller', { object_name: 'form' }
end
