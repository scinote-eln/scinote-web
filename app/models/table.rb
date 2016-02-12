class Table < ActiveRecord::Base
  validates :contents,
    presence: true,
    length: { maximum: 20971520 }

  belongs_to :created_by, foreign_key: 'created_by_id', class_name: 'User'
  belongs_to :last_modified_by, foreign_key: 'last_modified_by_id', class_name: 'User'
  has_one :step_table, inverse_of: :table
  has_one :step, through: :step_table

  has_one :result_table, inverse_of: :table
  has_one :result, through: :result_table
  has_many :report_elements, inverse_of: :table, dependent: :destroy

  after_save :update_ts_index

  def contents_utf_8
    contents.present? ? contents.force_encoding(Encoding::UTF_8) : nil
  end

  def update_ts_index
    if contents_changed?
      sql = "UPDATE tables " +
            "SET data_vector = " +
            "to_tsvector(substring(encode(contents::bytea, 'escape'), 9)) " +
            "WHERE id = " + Integer(id).to_s
      Table.connection.execute(sql)
    end
  end
end

