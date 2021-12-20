# frozen_string_literal: true

require 'rails_helper'

describe 'ResultPermissions' do
  include Canaid::Helpers::PermissionsHelper

  let(:user) { create :user, current_team_id: team.id }
  let(:team) { create :team }
  let(:result) { create :result, user: user, my_module: my_module }
  let(:my_module) { create :my_module, experiment: experiment, created_by: experiment.created_by }
  let(:experiment) { create :experiment, user: user }

  before do
    create_user_assignment(my_module, UserRole.find_by(name: I18n.t('user_roles.predefined.owner')), user)
  end

  describe 'can_read_result?' do
    it 'should be true for active result' do
      expect(can_read_result?(user, result)).to be_truthy
    end

    it 'should be true for archived result' do
      result.archive!(user)

      expect(can_read_result?(user, result)).to be_truthy
    end

    it 'should be true for archived experiment' do
      experiment.update(archived_on: Time.zone.now, archived_by: user)

      expect(can_read_result?(user, result)).to be_truthy
    end
  end

  describe 'can_manage_result?' do
    it 'should be true for active result' do
      expect(can_manage_result?(user, result)).to be_truthy
    end

    it 'should be false for archived result' do
      result.archive!(user)
      expect(can_manage_result?(user, result)).to be_falsey
    end

    it 'should be false for archived experiment' do
      experiment.update(archived_on: Time.zone.now, archived_by: user, archived: true)

      expect(can_manage_result?(user, result)).to be_falsey
    end
  end
end
