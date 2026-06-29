# frozen_string_literal: true

class NonExistantRecord
  attr_reader :name

  def initialize(name, params: nil)
    @name = name

    params&.each do |key, value|
      define_singleton_method key do
        value
      end
    end
  end
end
