# frozen_string_literal: true

module UserAssignments
  class BaseJob < ApplicationJob
    queue_as :high_priority
  end
end
