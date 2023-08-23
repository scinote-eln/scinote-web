# frozen_string_literal: true

class Result < ApplicationRecord
  include ArchivableModel
  include SearchableModel
  include SearchableByNameModel
  include ViewableModel

  auto_strip_attributes :name, nullify: false
  validates :name, length: { maximum: Constants::NAME_MAX_LENGTH }

  enum assets_view_mode: { thumbnail: 0, list: 1, inline: 2 }

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

  def duplicate(my_module, user, result_name: nil)
    ActiveRecord::Base.transaction do
      new_result = my_module.results.new(
        name: result_name || name,
        user: user
      )
      new_result.save!

      # Copy texts
      result_texts.each do |result_text|
        result_text.duplicate(new_result)
      end

      # Copy assets
      assets.each do |asset|
        new_asset = asset.dup
        new_asset.save!
        new_result.assets << new_asset
      end

      # Copy tables
      tables.each do |table|
        table.duplicate(new_result, user)
      end

      new_result
    end
  end

  def default_view_state
    { 'assets' => { 'sort' => 'new' } }
  end

  def validate_view_state(view_state)
    unless %w(new old atoz ztoa).include?(view_state.state.dig('assets', 'sort'))
      view_state.errors.add(:state, :wrong_state)
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

  def normalize_elements_position
    result_orderable_elements.order(:position).each_with_index do |element, index|
      element.update!(position: index) unless element.position == index
    end
  end
end
