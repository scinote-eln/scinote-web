# frozen_string_literal: true

class ReportTemplate < ApplicationRecord
  belongs_to :subject, polymorphic: true

  has_one_attached :odt_template_file
end
