# frozen_string_literal: true

class LabelTemplate < ApplicationRecord
  include SearchableModel

  enum language_type: { zpl: 0 }
  validates :name, presence: true, length: { minimum: Constants::NAME_MIN_LENGTH,
                                             maximum: Constants::NAME_MAX_LENGTH }
  validates :size, presence: true
  validates :content, presence: true

  def render(locals)
    locals.reduce(content.dup) do |rendered_content, (key, value)|
      rendered_content.gsub!(/\{\{#{key}\}\}/, value.to_s)
    end
  end
end
