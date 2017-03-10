require 'test_helper'

class SampleMyModuleTest < ActiveSupport::TestCase
  def setup
    @sample_module = sample_my_modules(:one)
  end

  test 'should validate with correct data' do
    assert @sample_module.valid?
  end

  test 'should not validate with non existent sample' do
    @sample_module.sample_id = 123123213
    assert_not @sample_module.valid?
    @sample_module.sample = nil
    assert_not @sample_module.valid?
  end

  test 'should not validate with non existent my_module' do
    @sample_module.my_module_id = 12312312
    assert_not @sample_module.valid?
    @sample_module.my_module = nil
    assert_not @sample_module.valid?
  end

  test 'should have association my_module <-> sample' do
    sample = Sample.create(name: 'test sample',
                           user: users(:jlaw),
                          team: teams(:biosistemika))
    my_module = MyModule.create(
      name: 'test module',
      experiment: experiments(:philadelphia),
      my_module_group: my_module_groups(:wf1)
    )

    assert_empty sample.my_modules
    assert_empty my_module.samples

    my_module.samples << sample
    assert_equal sample, MyModule.find(my_module.id).samples.first
  end
end
