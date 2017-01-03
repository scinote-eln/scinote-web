require 'test_helper'

class SampleTypeTest < ActiveSupport::TestCase
  def setup
    @sample_type = sample_types(:skin)
  end

  should validate_length_of(:name).is_at_most(Constants::NAME_MAX_LENGTH)
  should validate_presence_of(:name)
  should validate_presence_of(:organization)

  test 'should validate with correct data' do
    assert @sample_type.valid?
  end

  test 'should not validate without organization' do
    @sample_type.organization_id = 12321321
    assert_not @sample_type.valid?
    @sample_type.organization = nil
    assert_not @sample_type.valid?
  end
end
