# frozen_string_literal: true

class NonExistantRecord
  attr_reader :name

  def initialize(name)
    @name = name
  end
end
