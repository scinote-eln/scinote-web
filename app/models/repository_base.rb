# frozen_string_literal: true

class RepositoryBase < ApplicationRecord
<<<<<<< HEAD
  require 'sti_preload'

  include StiPreload
=======
>>>>>>> Pulled latest release
  include Discard::Model

  self.table_name = 'repositories'

  attribute :discarded_by_id, :integer

  belongs_to :team
  belongs_to :created_by, foreign_key: :created_by_id, class_name: 'User'
  has_many :repository_columns, foreign_key: :repository_id, inverse_of: :repository, dependent: :destroy
  has_many :repository_rows, foreign_key: :repository_id, inverse_of: :repository, dependent: :destroy
  has_many :repository_table_states, foreign_key: :repository_id, inverse_of: :repository, dependent: :destroy
  has_many :report_elements, inverse_of: :repository, dependent: :destroy, foreign_key: :repository_id

  auto_strip_attributes :name, nullify: false
  validates :team, presence: true
  validates :created_by, presence: true

  # Not discarded
  default_scope -> { kept }

  def cell_preload_includes
    cell_includes = []
    repository_columns.pluck(:data_type).each do |data_type|
<<<<<<< HEAD
      value_class = data_type.constantize
      next unless value_class.const_defined?('EXTRA_PRELOAD_INCLUDE')

      cell_includes << value_class::EXTRA_PRELOAD_INCLUDE
=======
      cell_includes << data_type.constantize::PRELOAD_INCLUDE
>>>>>>> Pulled latest release
    end
    cell_includes
  end

<<<<<<< HEAD
  def default_table_state
    raise NotImplementedError
  end

  def default_table_columns
    default_table_state['columns'].to_json
  end

  def default_columns_count
    default_table_state['columns'].length
  end

  def default_table_order_as_js_array
    default_table_state['order'].to_json
  end

=======
>>>>>>> Pulled latest release
  def destroy_discarded(discarded_by_id = nil)
    self.discarded_by_id = discarded_by_id
    destroy
  end
  handle_asynchronously :destroy_discarded, queue: :clear_discarded_repository, priority: 20
end
