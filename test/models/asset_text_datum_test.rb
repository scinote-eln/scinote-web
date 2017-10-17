require 'test_helper'

class AssetTextDatumTest < ActiveSupport::TestCase
  def setup
    @asset_data = asset_text_datum(:one) 
  end

  test "should validate with valid data" do
skip
    assert @asset_data.valid?
  end

  test "should check if data is present" do
skip
    @asset_data.data = ""
    assert_not @assert_data.valid?
    @asset_data.data = nil
    assert_not @assert_data.valid?
  end

  test "should check if associated asset is valid" do
skip
    assert_not asset_text_datum(:invalid_asset_id)
    assert_not asset_text_datum(:invalid_asset_value)
  end
end
