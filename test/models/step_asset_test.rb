require 'helpers/fake_test_helper'

class StepAssetTest < ActiveSupport::TestCase
  include FakeTestHelper

  def setup
    @step = steps(:empty)
    @step_asset = step_assets(:test)
  end

  test "should not validate with non existent asset_id" do
    @step_asset.asset_id = 1231295
    assert_not @step_asset.valid?
    @step_asset.asset = nil
    assert_not @step_asset.valid?
  end

  test "should not validate with non existent step_id" do
    @step_asset.step_id = 1232132
    assert_not @step_asset.valid?
    @step_asset.step = nil
    assert_not @step_asset.valid?
  end

  test "should have association step -> asset" do
    assert_empty @step.assets

    asset = Asset.new(file: generate_csvfile)
    asset.step = @step
    asset.save

    @step.assets << asset
    assert_equal asset, Step.find(@step.id).assets.first, "There is no association between step -> asset."
  end
end
