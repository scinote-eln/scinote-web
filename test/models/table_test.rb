require 'test_helper'

class TableTest < ActiveSupport::TestCase

  def setup
    @table = tables(:one)
  end

  test "should validate with correct data" do
    assert @table.valid?
  end

  test "should not validate without content" do
    @table.contents = nil
    assert_not @table.save, "Table was created without content."
  end

  test "should not allow tables larger than 20MB" do
    content = generate_string(21)
    table = Table.new(contents: content)
    assert_not table.valid?
  end

  test "should allow tables <=  20MB" do
    content = generate_string(20)
    table = Table.new(contents: content)
    assert table.valid?
  end

  private
  # Generates string of size size_in_mb
  def generate_string(size_in_mb)
    require 'securerandom'
    one_megabyte = 2 ** 20
    SecureRandom.random_bytes(size_in_mb * one_megabyte)
  end
end
