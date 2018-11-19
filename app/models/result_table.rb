class ResultTable < ApplicationRecord
  validates :result, :table, presence: true

  belongs_to :result, inverse_of: :result_table, touch: true, optional: true
  belongs_to :table,
             inverse_of: :result_table,
             dependent: :destroy,
             optional: true
end
