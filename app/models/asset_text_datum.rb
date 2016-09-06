class AssetTextDatum < ActiveRecord::Base
  include SearchableModel

  validates :data, presence: true
  validates :asset, presence: true, uniqueness: true
  belongs_to :asset, inverse_of: :asset_text_datum

  after_save :update_ts_index

  def update_ts_index
    if data_changed?
      sql = "UPDATE asset_text_data " +
            "SET data_vector = to_tsvector(data) " +
            "WHERE id = " + Integer(id).to_s
      AssetTextDatum.connection.execute(sql)
    end
  end
end
