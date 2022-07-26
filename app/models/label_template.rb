# frozen_string_literal: true

class LabelTemplate < ApplicationRecord
  include SearchableModel

  enum language_type: { zpl: 0 }
  belongs_to :last_modified_by,
             class_name: 'User'
  belongs_to :created_by,
             class_name: 'User'
  validates :name, presence: true, length: { minimum: Constants::NAME_MIN_LENGTH,
                                             maximum: Constants::NAME_MAX_LENGTH }
  validates :size, presence: true
  validates :content, presence: true
  validates :description, length: { minimum: Constants::NAME_MIN_LENGTH,
                                    maximum: Constants::NAME_MAX_LENGTH }

  def render(locals)
    locals.reduce(content.dup) do |rendered_content, (key, value)|
      rendered_content.gsub!(/\{\{#{key}\}\}/, value.to_s)
    end
  end
end
