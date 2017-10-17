require 'test_helper'

class ProtocolKeywordTest < ActiveSupport::TestCase

  def setup
    @kw = protocol_keywords(:kw1)
  end

  should validate_presence_of(:name)
  should validate_length_of(:name).is_at_most(Constants::NAME_MAX_LENGTH)
end
