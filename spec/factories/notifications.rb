# frozen_string_literal: true

FactoryBot.define do
  factory :notification do
    title do
      '<i>Admin</i> was added as Owner to project ' \
          '<strong>Demo project - qPCR</strong> by <i>User</i>.'
    end
    message { 'Project: <a href=\"/projects/3\"> Demo project - qPCR</a>' }
    type_of { 'assignment' }
  end
end
