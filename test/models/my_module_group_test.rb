require 'test_helper'
require 'helpers/searchable_model_test_helper'

class MyModuleGroupTest < ActiveSupport::TestCase
  include SearchableModelTestHelper

  def setup
    @module_group = my_module_groups(:wf1)
  end

  should validate_presence_of(:name)
  should validate_length_of(:name)
    .is_at_most(Constants::NAME_MAX_LENGTH)

  test "should validate with valid data" do
    assert @module_group.valid?
  end

  test "where_attributes_like should work" do
    attributes_like_test(MyModuleGroup, :name, "expression")
  end
end
