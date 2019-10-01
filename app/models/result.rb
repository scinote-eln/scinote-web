# frozen_string_literal: true

class Result < ApplicationRecord
  include ArchivableModel
  include SearchableModel
  include SearchableByNameModel

  auto_strip_attributes :name, nullify: false
  validates :user, :my_module, presence: true
  validates :name, length: { maximum: Constants::NAME_MAX_LENGTH }

  belongs_to :user, inverse_of: :results
  belongs_to :last_modified_by, foreign_key: 'last_modified_by_id', class_name: 'User', optional: true
  belongs_to :archived_by, foreign_key: 'archived_by_id', class_name: 'User', optional: true
  belongs_to :restored_by, foreign_key: 'restored_by_id', class_name: 'User', optional: true
  belongs_to :my_module, inverse_of: :results
  has_one :result_asset, inverse_of: :result, dependent: :destroy
  has_one :asset, through: :result_asset
  has_one :result_table, inverse_of: :result, dependent: :destroy
  has_one :table, through: :result_table
  has_one :result_text, inverse_of: :result, dependent: :destroy
  has_many :result_comments, foreign_key: :associated_id, dependent: :destroy
  has_many :report_elements, inverse_of: :result, dependent: :destroy

  accepts_nested_attributes_for :result_text
  accepts_nested_attributes_for :asset
  accepts_nested_attributes_for :table

  def self.search(user,
                  include_archived,
                  query = nil,
                  page = 1,
                  _current_team = nil,
                  options = {})
    module_ids =
      MyModule
      .search(user, include_archived, nil, Constants::SEARCH_NO_LIMIT)
      .pluck(:id)

    new_query =
      Result
      .distinct
      .joins('LEFT JOIN result_texts ON results.id = result_texts.result_id')
      .where('results.my_module_id IN (?)', module_ids)
      .where_attributes_like(['results.name', 'result_texts.text'],
                             query, options)

    new_query = new_query.where('results.archived = ?', false) unless include_archived

    # Show all results if needed
    if page == Constants::SEARCH_NO_LIMIT
      new_query
    else
      new_query
        .limit(Constants::SEARCH_LIMIT)
        .offset((page - 1) * Constants::SEARCH_LIMIT)
    end
  end

  def self.viewable_by_user(user, teams)
    where(my_module: MyModule.viewable_by_user(user, teams))
  end

  def navigable?
    !my_module.archived? && my_module.navigable?
  end

  def space_taken
    is_asset ? result_asset.space_taken : 0
  end

  def last_comments(last_id = 1, per_page = Constants::COMMENTS_SEARCH_LIMIT)
    last_id = Constants::INFINITY if last_id <= 1
    comments = ResultComment.joins(:result)
                            .where(results: { id: id })
                            .where('comments.id <  ?', last_id)
                            .order(created_at: :desc)
                            .limit(per_page)
    comments.reverse
  end

  def is_text
    result_text.present?
  end

  def is_table
    table.present?
  end

  def is_asset
    asset.present?
  end

  def unlocked?(result)
    if result.is_asset
      !result.asset.locked?
    else
      true
    end
  end

  def editable?
    return false if is_asset && asset.file.metadata['asset_type'] == 'marvinjs'

    true
  end
end
