# frozen_string_literal: true

class RepositoryTableFilter < ApplicationRecord
  belongs_to :repository, inverse_of: :repository_table_filters
  belongs_to :created_by, class_name: 'User', inverse_of: :repository_table_filters
  has_many :repository_table_filter_elements, dependent: :destroy

  validates :name, :repository, :created_by, presence: true
  validates_associated :repository_table_filter_elements
end
