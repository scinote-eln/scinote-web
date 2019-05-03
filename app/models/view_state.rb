# frozen_string_literal:true

class ViewState < ApplicationRecord
  belongs_to :user
  belongs_to :viewable, polymorphic: true

  validates :viewable_id, uniqueness: {
    scope: %i(viewable_type user_id),
    message: :not_unique
  }
end
