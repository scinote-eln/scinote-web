# frozen_string_literal: true

class LabelPrinter < ApplicationRecord
  enum type_of: { fluics: 0 }
  enum language_type: { zpl: 0 }

  validates :name, presence: true
  validates :type_of, presence: true
  validates :language_type, presence: true

  def ready?
    true # TODO
  end
end
