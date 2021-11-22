# frozen_string_literal: true

class BmtFilter < ApplicationRecord

  attr_accessor :delete_url

  belongs_to :created_by,
             foreign_key: :created_by_id,
             class_name: 'User',
             optional: true

  validates :name, :filters, presence: true
end
