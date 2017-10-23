require 'test_helper'
require 'helpers/searchable_model_test_helper'

class MyModuleGroupTest < ActiveSupport::TestCase
  include SearchableModelTestHelper

  def setup
    @module_group = my_module_groups(:wf1)
  end

  test "should validate with valid data" do
    assert @module_group.valid?
  end
end
