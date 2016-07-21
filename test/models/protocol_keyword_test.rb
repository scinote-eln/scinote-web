require 'test_helper'

class ProtocolKeywordTest < ActiveSupport::TestCase

  def setup
    @kw = protocol_keywords(:kw1)
  end

  test "should not validate without name" do
    assert @kw.valid?
    @kw.name = nil
    assert_not @kw.valid?
  end

  test "should not validate with name too long" do
    @kw.name = "A" * 50
    assert @kw.valid?
    @kw.name = "A" * 51
    assert_not @kw.valid?
  end

end