# frozen_string_literal: true

module ObservableModel
  extend ActiveSupport::Concern

  included do
    after_update :run_observers
  end

  private

  def run_observers
    raise NotImplemented
  end
end
