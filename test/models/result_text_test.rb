require 'test_helper'

class ResultTextTest < ActiveSupport::TestCase
  def setup
    @result_text = result_texts(:test)
  end

  test "should validate with correct data" do
    assert @result_text.valid?
  end

  test "should not validate without text" do
    @result_text.text = ""
    assert_not @result_text.valid?
    @result_text.text = nil
    assert_not @result_text.valid?
  end

  test "should not validate with non existent result" do
    @result_text.result_id = 1232132
    assert_not @result_text.valid?
    @result_text.result = nil
    assert_not @result_text.valid?
  end

  test "should have association result -> result_text" do
    result = Result.new(
      name: "Result test",
      user: users(:steve),
      my_module: my_modules(:list_of_samples))
    result_text = ResultText.new(
      text: "test")

    assert_nil result.result_text
    result.result_text = result_text
    result.save
    assert_equal result_text, Result.find(result.id).result_text
  end
end
