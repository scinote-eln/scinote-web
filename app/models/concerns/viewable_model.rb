# frozen_string_literal: true

module ViewableModel
  extend ActiveSupport::Concern

  included do
    has_many :view_states, as: :viewable, dependent: :destroy
  end

  def current_view_state(user)
    state = view_states.where(user: user).take
    state || view_states.create!(user: user, state: default_view_state)
  end
end
