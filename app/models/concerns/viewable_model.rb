# frozen_string_literal: true

module ViewableModel
  extend ActiveSupport::Concern

  included do
    has_many :view_states, as: :viewable, dependent: :destroy
  end

  # This module requres that the class which includes it implements these methods:
  # => default_view_state, returning hash with default state representation
  # => validate_view_state(view_state), custom validator for the state hash

  def default_view_state
    raise NotImplementedError, 'default_view_state should be implemented!'
  end

  def validate_view_state(_view_state)
    raise NotImplementedError, 'validate_view_state(view_state) should be implemented!'
  end

  def current_view_state(user)
    state = view_states.find_by(user: user)
    state || view_states.create!(user: user, state: default_view_state)
  end
end
