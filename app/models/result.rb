# frozen_string_literal: true

class Result < ApplicationRecord
  include ArchivableModel
  include SearchableModel
  include SearchableByNameModel

  auto_strip_attributes :name, nullify: false
  validates :name, length: { maximum: Constants::NAME_MAX_LENGTH }

  belongs_to :user, inverse_of: :results
  belongs_to :last_modified_by, class_name: 'User', optional: true
  belongs_to :archived_by, class_name: 'User', optional: true
  belongs_to :restored_by, class_name: 'User', optional: true
  belongs_to :my_module, inverse_of: :results
  has_many :result_orderable_elements, inverse_of: :result, dependent: :destroy
  has_many :result_assets, inverse_of: :result, dependent: :destroy
  has_many :assets, through: :result_assets
  has_many :result_tables, inverse_of: :result, dependent: :destroy
  has_many :tables, through: :result_tables
  has_many :result_texts, inverse_of: :result, dependent: :destroy
  has_many :result_comments, inverse_of: :result, foreign_key: :associated_id, dependent: :destroy
  has_many :report_elements, inverse_of: :result, dependent: :destroy

  accepts_nested_attributes_for :result_texts
  accepts_nested_attributes_for :assets
  accepts_nested_attributes_for :tables

  def self.search(user,
                  include_archived,
                  query = nil,
                  page = 1,
                  _current_team = nil,
                  options = {})
    module_ids = MyModule.search(user, include_archived, nil, Constants::SEARCH_NO_LIMIT).pluck(:id)

    new_query =
      Result
      .distinct
      .left_outer_joins(:result_texts)
      .where(results: { my_module_id: module_ids })
      .where_attributes_like(['results.name', 'result_texts.text'], query, options)

    new_query = new_query.active unless include_archived

    # Show all results if needed
    if page == Constants::SEARCH_NO_LIMIT
      new_query
    else
      new_query.limit(Constants::SEARCH_LIMIT).offset((page - 1) * Constants::SEARCH_LIMIT)
    end
  end

  def self.viewable_by_user(user, teams)
    where(my_module: MyModule.viewable_by_user(user, teams))
  end

  def self.filter_by_teams(teams = [])
    return self if teams.blank?

    joins(my_module: { experiment: :project }).where(my_module: { experiments: { projects: { team: teams } } })
  end

  def navigable?
    !my_module.archived? && my_module.navigable?
  end

  def space_taken
    result_assets.joins(asset: { file_attachment: :blob }).sum('active_storage_blobs.byte_size')
  end

  def last_comments(last_id = 1, per_page = Constants::COMMENTS_SEARCH_LIMIT)
    last_id = Constants::INFINITY if last_id <= 1
    comments = ResultComment.joins(:result)
                            .where(results: { id: id })
                            .where('comments.id <  ?', last_id)
                            .order(created_at: :desc)
                            .limit(per_page)
    ResultComment.from(comments, :comments).order(created_at: :asc)
  end

  def is_text
    raise StandardError, 'Deprecated method, needs to be replaced!'
  end

  def is_table
    raise StandardError, 'Deprecated method, needs to be replaced!'
  end

  def is_asset
    raise StandardError, 'Deprecated method, needs to be replaced!'
  end

  def unlocked?(result)
    result.assets.none?(&:locked?)
  end

  def comments
    result_comments
  end
end
