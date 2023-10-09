# frozen_string_literal: true

class Settings < ApplicationRecord
  attr_accessor :merged_values

  before_validation -> { self.values = merged_values || values }

  def self.instance
    first || new
  end

  def values
    self.merged_values ||= super
    self.class.instance_methods(false).grep(/^load_values_from_[A-Z0-9_]*/).each do |method|
      self.merged_values = self.merged_values.merge(public_send(method))
    end
    merged_values
  end

  def load_values_from_env
    raise NotImplementedError
  end
end
