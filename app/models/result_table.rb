class ResultTable < ActiveRecord::Base
  validates :result, :table, presence: true

  belongs_to :result, inverse_of: :result_table
  belongs_to :table, inverse_of: :result_table, dependent: :destroy
end
