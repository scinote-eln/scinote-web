# frozen_string_literal: true

class SmartAnnotationNotification < BaseNotification
  def self.subtype
    :smart_annotation_added
  end
end
