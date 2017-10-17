require 'test_helper'

class UserTeamTest < ActiveSupport::TestCase
  def setup
    @user_team = user_teams(:one)
  end

  # Test role attribute
  test 'should not save user team without role' do
    assert_not user_teams(:without_role).save,
               'Saved user team without role'
  end

  test 'should have default role' do
    assert @user_team.normal_user?,
           'User team does not have default normal_user role'
  end

  test 'should set valid role values' do
    assert_nothing_raised(
      ArgumentError,
      'User team role was set with invalid role value'
    ) do
      @user_team.role = 0
      @user_team.role = 1
      @user_team.role = 2
      @user_team.role = 'guest'
      @user_team.role = 'normal_user'
      @user_team.role = 'admin'
    end
  end

  test 'should not have undefined role' do
    assert_raises(
      ArgumentError,
      'User team role can not be set to undefined numeric role value'
    ) { @user_team.role = 5 }
    assert_raises(
      ArgumentError,
      'User team role can not be set to undefined role value'
    ) { @user_team.role = 'gatekeeper' }
  end

  # Test user attribute
  test 'should not save user team without user' do
    assert_not user_teams(:without_user).save,
               'Saved user team without user'
  end

  test 'should not associate unexisting user' do
    assert_raises(
      ActiveRecord::RecordInvalid,
      'User team saved unexisting user association'
    ) { user_teams(:with_invalid_user).save! }
  end

  # Test team attribute
  test 'should not save user team without team' do
    assert_not user_teams(:without_team).save,
               'Saved user team without team'
  end

  test 'should not associate unexisting team' do
    assert_raises(
      ActiveRecord::RecordInvalid,
      'User team saved unexisting team association'
    ) { user_teams(:with_invalid_team).save! }
  end
end
