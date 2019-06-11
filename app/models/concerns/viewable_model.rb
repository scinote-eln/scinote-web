# frozen_string_literal: true

module ViewableModel
  extend ActiveSupport::Concern

  # This module requres that the class which includes it implements these methods:
  # => default_view_state, returning hash with default state representation
  # => validate_view_state(view_state), custom validator for the state hash

  included do
    has_many :view_states, as: :viewable, dependent: :destroy
  end

  def current_view_state(user)
    state = view_states.where(user: user).take
    state || view_states.create!(user: user, state: default_view_state)
  end
end
