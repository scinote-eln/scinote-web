class Result < ActiveRecord::Base
  include ArchivableModel, SearchableModel

  validates :user, :my_module, presence: true
  validates :name,
    length: { maximum: 50 }
  validate :text_or_asset_or_table

  belongs_to :user, inverse_of: :results
  belongs_to :last_modified_by, foreign_key: 'last_modified_by_id', class_name: 'User'
  belongs_to :archived_by, foreign_key: 'archived_by_id', class_name: 'User'
  belongs_to :restored_by, foreign_key: 'restored_by_id', class_name: 'User'
  belongs_to :my_module, inverse_of: :results
  has_one :result_asset,
    inverse_of: :result,
    dependent: :destroy
  has_one :asset, through: :result_asset
  has_one :result_table,
    inverse_of: :result,
    dependent: :destroy
  has_one :table, through: :result_table
  has_one :result_text,
    inverse_of: :result,
    dependent: :destroy
  has_many :result_comments,
    inverse_of: :result,
    dependent: :destroy
  has_many :comments, through: :result_comments
  has_many :report_elements, inverse_of: :result, dependent: :destroy

  accepts_nested_attributes_for :result_text
  accepts_nested_attributes_for :asset
  accepts_nested_attributes_for :table

  def self.search(user, include_archived, query = nil, page = 1)
    module_ids =
      MyModule
      .search(user, include_archived, nil, SHOW_ALL_RESULTS)
      .select("id")

    if query
      if include_archived
        new_query = Result
          .distinct
          .joins("LEFT JOIN result_texts ON results.id = result_texts.result_id")
          .joins("LEFT JOIN result_tables ON results.id = result_tables.result_id")
          .joins("LEFT JOIN tables ON result_tables.table_id = tables.id")
          .where("results.my_module_id IN (?)", module_ids)
          .where(
            "results.name ILIKE ? " +
            "OR result_texts.text ILIKE ? " +
            "OR tables.data_vector @@ plainto_tsquery(?) ",
            "%" + query + "%",
            "%" + query + "%",
            query
          )
      else
        new_query = Result
          .distinct
          .joins("LEFT JOIN result_texts ON results.id = result_texts.result_id")
          .joins("LEFT JOIN result_tables ON results.id = result_tables.result_id")
          .joins("LEFT JOIN tables ON result_tables.table_id = tables.id")
          .where("results.my_module_id IN (?)", module_ids)
          .where("results.archived = ?", false)
          .where(
            "results.name ILIKE ? " +
            "OR result_texts.text ILIKE ? " +
            "OR tables.data_vector @@ plainto_tsquery(?) ",
            "%" + query + "%",
            "%" + query + "%",
            query
          )
      end

    else
      if include_archived
        new_query = Result
          .distinct
          .where("results.my_module_id IN (?)", module_ids)
      else
        new_query = Result
          .distinct
          .where("results.my_module_id IN (?)", module_ids)
          .where("results.archived = ?", false)
      end
    end

    # Show all results if needed
    if page == SHOW_ALL_RESULTS
      new_query
    else
      new_query
        .limit(SEARCH_LIMIT)
        .offset((page - 1) * SEARCH_LIMIT)
    end
  end

  def space_taken
    is_asset ? result_asset.space_taken : 0
  end

  def last_comments(last_id = 1, per_page = 20)
    last_id = 9999999999999 if last_id <= 1
    Comment.joins(:result_comment)
    .where(result_comments: {result_id: id})
    .where('comments.id <  ?', last_id)
    .order(created_at: :desc)
    .limit(per_page)
  end

  def is_text
    self.result_text.present?
  end

  def is_table
    self.table.present?
  end

  def is_asset
    self.asset.present?
  end

  private
  def text_or_asset_or_table
    num_of_assigns = 0
    num_of_assigns += result_text.blank? ? 0 : 1
    num_of_assigns += asset.blank? ? 0 : 1
    num_of_assigns += table.blank? ? 0 : 1

    # Theoretically, we should make sure == 1, not > 1,
    # but due to GUI problems this is how it is
    if num_of_assigns > 1
      errors.add(:base, "Result can only be instance of text/asset/table.")
    elsif num_of_assigns < 1
      errors.add(:base, "Result should be instance of text/asset/table.")
    end
  end
end
