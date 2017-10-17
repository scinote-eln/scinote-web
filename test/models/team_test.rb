require 'test_helper'

class TeamTest < ActiveSupport::TestCase
  def setup
    @team = teams(:test)
  end

  should validate_length_of(:name)
    .is_at_least(Constants::NAME_MIN_LENGTH)
    .is_at_most(Constants::NAME_MAX_LENGTH)

  should validate_length_of(:description)
    .is_at_most(Constants::TEXT_MAX_LENGTH)

  test 'should validate team default values' do
    assert @team.valid?
  end

  test 'should have non-blank name' do
    @team.name = ''
    assert @team.invalid?, 'Team with blank name returns valid? = true'
  end

  test 'should have space_taken present' do
    @team.space_taken = nil
    assert @team.invalid?,
           'Team without space_taken returns valid? = true'
  end

  test 'space_taken_defaults_to_value' do
    team = Team.new
    assert_equal Constants::MINIMAL_TEAM_SPACE_TAKEN, team.space_taken
  end

  test 'should open spreadsheet file' do
    skip
  end
end
