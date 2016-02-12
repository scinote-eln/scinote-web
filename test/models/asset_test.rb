require 'test_helper'
require 'helpers/searchable_model_test_helper'
require 'helpers/fake_test_helper'

class AssetTest < ActiveSupport::TestCase
  include SearchableModelTestHelper
  include FakeTestHelper

  def setup
    @user = users(:nora)
    @step = Step.create(
      name: "Step test",
      position: 0,
      completed: 0,
      user: @user,
      my_module: my_modules(:sample_prep))
    @result = Result.create(
      name: "Result test",
      user: @user,
      my_module: my_modules(:list_of_samples),
      asset: assets(:one)
    )

    @comment = Comment.create(
      message: "random comment",
      user: @user)
    @asset = Asset.new(file: generate_csvfile)
  end

  def teardown
    @asset.file = nil
    if @asset.persisted? then
      @asset.save
      @asset.destroy
    end
  end

  test "should not validate with step and result present" do
    @asset.step = @step
    @asset.result = @result
    assert_not @asset.valid?
  end

  test "should not validate without step and result present" do
    skip # Omit due to GUI problems (see asset.rb)
    assert @asset.result.blank?
    assert @asset.step.blank?
    assert_not @asset.valid?
  end

  test "should not validate without estimated_size present" do
    @asset.step = @step
    @asset.estimated_size = nil
    assert @asset.invalid?
  end

  test "estimated size defaults to 0" do
    asset = Asset.new
    assert 0, asset.estimated_size
  end

  test "should validate with only step present" do
    assert @asset.result.blank?
    @asset.step = @step
    assert @asset.valid?
  end

  test "should validate with only result present" do
    assert @asset.step.blank?
    @asset.result = @result
    assert @asset.valid?
  end


  test "should not allow files larger than 20MB" do
     asset = Asset.new(file: generate_file(21))
     asset.step = @step
     assert_not asset.valid?
  end

  test "should allow files <  20MB" do
    asset = Asset.new(file: generate_file(19))
    asset.step = @step
    assert asset.valid?
  end

  test "where_attributes_like should work" do
    attributes_like_test(Asset, :file_file_name, "file")
  end
end
