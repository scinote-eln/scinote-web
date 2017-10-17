require 'test_helper'
require 'helpers/searchable_model_test_helper'

class SampleTest < ActiveSupport::TestCase
  include SearchableModelTestHelper

  def setup
    @sample = samples(:sample1)
    @user = users(:jlaw)
  end

  test 'should validate with correct data' do
    assert @sample.valid?
  end

  test 'should not validate without name' do
    @sample.name = nil
    assert_not @sample.valid?
    @sample.name = ''
    assert_not @sample.valid?
  end

  test 'should not validate with to long name' do
    @sample.name *= 50
    assert_not @sample.valid?
  end

  test 'should not validate with non existent user' do
    @sample.user_id = 1232132
    assert_not @sample.valid?
    @sample.user = nil
    assert_not @sample.valid?
  end

  test 'should not validate with non existent team' do
    @sample.team_id = 1231232
    assert_not @sample.valid?
    @sample.team = nil
    assert_not @sample.valid?
  end

  test 'where_attributes_like should work' do
    attributes_like_test(Sample, :name, 'dna')
  end

  test 'should get user\'s samples' do
    samples = Sample.search(@user, false)
    assert_equal 5, samples.size
  end

  test 'should search user\'s samples by name' do
    samples = Sample.search(@user, false, 'test')
    assert_equal 2, samples.size
  end
end
