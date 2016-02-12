class AssetTextDatum < ActiveRecord::Base
  include SearchableModel

  validates :data, presence: true
  validates :asset, presence: true, uniqueness: true
  belongs_to :asset

  after_save :update_ts_index

  def self.search(user, include_archived, query = nil, page = 1)

    module_ids =
      MyModule
      .search(user, include_archived, nil, SHOW_ALL_RESULTS)
      .select("id")

    # Trim whitespace and replace it with OR character. Make prefixed
    # wildcard search term and escape special characters.
    # For example, search term 'demo project' is transformed to
    # 'demo:*|project:*' which makes word inclusive search with postfix
    # wildcard.
    s_query = query.strip
      .split(/\s+/)
      .map {|t| t + ":*" }
      .join("|")
      .gsub('\'', '"')
    # make prefixed wildcard search term
    query = query.gsub(":*", "") + ":*"

    ids = AssetTextDatum
      .select(:id)
      .distinct
      .joins(:asset)
      .joins("LEFT JOIN result_assets ON assets.id = result_assets.asset_id")
      .joins("LEFT JOIN results ON result_assets.result_id = results.id")
      .joins("LEFT JOIN step_assets ON assets.id = step_assets.asset_id")
      .joins("LEFT JOIN steps ON step_assets.step_id = steps.id")
      .joins("INNER JOIN my_modules ON results.my_module_id = my_modules.id OR steps.my_module_id = my_modules.id")
      .where("my_modules.id IN (?)", module_ids)
      .where("data_vector @@ to_tsquery(?)", s_query)

    # Limit results if needed
    if page != SHOW_ALL_RESULTS
      ids = ids
        .limit(SEARCH_LIMIT)
        .offset((page - 1) * SEARCH_LIMIT)
    end

    AssetTextDatum
      .select("*")
      .select("ts_headline(data, to_tsquery('" + s_query + "'),
        'StartSel=<mark>, StopSel=</mark>') headline")
      .where("id IN (?)",  ids)
  end

  def update_ts_index
    if data_changed?
      sql = "UPDATE asset_text_data " +
            "SET data_vector = to_tsvector(data) " +
            "WHERE id = " + Integer(id).to_s
      AssetTextDatum.connection.execute(sql)
    end
  end
end
