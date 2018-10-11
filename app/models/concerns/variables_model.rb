# frozen_string_literal: true

module VariablesModel
  extend ActiveSupport::Concern

  @@default_variables = HashWithIndifferentAccess.new

  included do
    serialize :variables, JsonbHashSerializer
    after_initialize :init_default_variables, if: :new_record?
  end

  class_methods do
    def default_variables(dfs)
      @@default_variables.merge!(dfs)
    end
  end

  protected

  def init_default_variables
    self.variables = @@default_variables
  end
end
