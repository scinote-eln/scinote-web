require 'test_helper'

class SampleGroupTest < ActiveSupport::TestCase
  def setup
    @sample_group = sample_groups(:blood)
  end

  should validate_presence_of(:name)
  should validate_length_of(:name).is_at_most(Constants::NAME_MAX_LENGTH)
  should validate_presence_of(:color)
  should validate_length_of(:color).is_at_most(Constants::COLOR_MAX_LENGTH)
  should validate_presence_of(:team)

  test 'should validate with correct data' do
    assert @sample_group.valid?
  end

  test 'should not validate without team' do
    @sample_group.team = nil
    assert_not @sample_group.valid?
  end
end
