require 'test_helper'
require 'helpers/fake_test_helper'

class ResultAssetTest < ActiveSupport::TestCase
  include FakeTestHelper

  def setup
    @result_asset = result_assets(:test)
  end

  test "should not validate with non existent asset_id" do
    @result_asset.asset_id = 1231295
    assert_not @result_asset.valid?
    @result_asset.asset = nil
    assert_not @result_asset.valid?
  end

  test "should not validate with non existent result_id" do
    @result_asset.result_id = 123123
    assert_not @result_asset.valid?
    @result_asset.result = nil
    assert_not @result_asset.valid?
  end

  test "should have association result -> asset" do
    result = results(:two)
    asset = Asset.new(file: generate_csvfile)
    result.asset = asset
    assert result.save
    assert_equal asset, Result.find(result.id).asset, "There is no association between result -> asset."
  end
end
