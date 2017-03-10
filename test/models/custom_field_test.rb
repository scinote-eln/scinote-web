require 'test_helper'

class CustomFieldTest < ActiveSupport::TestCase
  def setup
    @custom_field = custom_fields(:volume)
  end

  should validate_presence_of(:name)
  should validate_length_of(:name).is_at_most(Constants::NAME_MAX_LENGTH)
  should validate_exclusion_of(:name)
    .in_array(['Assigned',
               'Sample name',
               'Sample type',
               'Sample group',
               'Added on',
               'Added by'])

  test 'should validate with correct data' do
    assert @custom_field.valid?
  end

  test 'should not validate with non existent user' do
    @custom_field.user_id = 11231231
    assert_not @custom_field.valid?
    @custom_field.user = nil
    assert_not @custom_field.valid?
  end

  test 'should not validate with non existent team' do
    @custom_field.team_id = 1231231
    assert_not @custom_field.valid?
    @custom_field.team = nil
    assert_not @custom_field.valid?
  end
end
