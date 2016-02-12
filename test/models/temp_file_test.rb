require 'test_helper'

class TempFileTest < ActiveSupport::TestCase

  def setup
    @temp_file = temp_files(:one)
  end

  test "should not save temp file without session" do
    @temp_file.session_id = nil
    assert_not @temp_file.save, "Saved temp file without session"
  end
end
