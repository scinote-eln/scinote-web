# frozen_string_literal: true

class Result < ApplicationRecord
  include ArchivableModel
  include SearchableModel
  include SearchableByNameModel
  include ViewableModel
  include ObservableModel
  include Discard::Model

  default_scope -> { kept }

  auto_strip_attributes :name, nullify: false
  validates :name, length: { maximum: Constants::NAME_MAX_LENGTH }

  SEARCHABLE_ATTRIBUTES = ['results.name', :children].freeze

  enum assets_view_mode: { thumbnail: 0, list: 1, inline: 2 }

  belongs_to :user, inverse_of: :results
  belongs_to :last_modified_by, class_name: 'User', optional: true
  belongs_to :archived_by, class_name: 'User', optional: true
  belongs_to :restored_by, class_name: 'User', optional: true
  belongs_to :my_module, inverse_of: :results
  delegate :team, to: :my_module
  has_many :result_orderable_elements, inverse_of: :result, dependent: :destroy
  has_many :result_assets, inverse_of: :result, dependent: :destroy
  has_many :assets, through: :result_assets, dependent: :destroy
  has_many :result_tables, inverse_of: :result, dependent: :destroy
  has_many :tables, through: :result_tables, dependent: :destroy
  has_many :result_texts, inverse_of: :result, dependent: :destroy
  has_many :result_comments, inverse_of: :result, foreign_key: :associated_id, dependent: :destroy
  has_many :report_elements, inverse_of: :result, dependent: :destroy
  has_many :step_results, inverse_of: :result, dependent: :destroy
  has_many :steps, through: :step_results

  accepts_nested_attributes_for :result_texts
  accepts_nested_attributes_for :assets
  accepts_nested_attributes_for :tables

  before_save :ensure_default_name
  after_discard :delete_step_results
  after_discard do
    CleanupUserSettingsJob.perform_later('result_states', id)
  end

  def self.search(user,
                  include_archived,
                  query = nil,
                  teams = user.teams,
                  _options = {})
    new_query = joins(:my_module)
                .where(
                  my_modules: {
                    id: MyModule.with_granted_permissions(user, MyModulePermissions::READ, teams).select(:id)
                  }
                )

    unless include_archived
      new_query = new_query.joins(my_module: { experiment: :project })
                           .active
                           .where(my_modules: { archived: false },
                                  experiments: { archived: false },
                                  projects: { archived: false })
    end

    new_query.where_attributes_like_boolean(SEARCHABLE_ATTRIBUTES, query)
  end

  def self.where_children_attributes_like(query)
    from(
      "(#{joins(:result_texts).where_attributes_like(ResultText::SEARCHABLE_ATTRIBUTES, query).to_sql}
      UNION
      #{joins(result_tables: :table ).where_attributes_like(Table::SEARCHABLE_ATTRIBUTES, query).to_sql}
      UNION
      #{joins(:result_comments).where_attributes_like(ResultComment::SEARCHABLE_ATTRIBUTES, query).to_sql}
      ) AS results",
      :results
    )
  end

  def self.find_page_number(result_id, per_page = Kaminari.config.default_per_page)
    position = pluck(:id).index(result_id)
    (position.to_f / per_page).ceil
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
      assets_to_clone = assets.map do |asset|
        new_asset = asset.dup
        new_asset.save!
        new_result.assets << new_asset

        [asset.id, new_asset.id]
      end

      # Copy tables
      tables.each do |table|
        table.duplicate(new_result, user)
      end

      Result.delay(queue: :assets).deep_clone_assets(assets_to_clone)

      new_result
    end
  end

  # Deep-clone given array of assets
  def self.deep_clone_assets(assets_to_clone)
    ActiveRecord::Base.no_touching do
      assets_to_clone.each do |src_id, dest_id|
        src = Asset.find_by(id: src_id)
        dest = Asset.find_by(id: dest_id)
        dest.destroy! if src.blank? && dest.present?
        next unless src.present? && dest.present?

        # Clone file
        src.duplicate_file(dest)
      end
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

  def self.readable_by_user(user, teams)
    where(my_module: MyModule.readable_by_user(user, teams))
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

  def ensure_default_name
    self.name = name.presence || I18n.t('my_modules.results.default_name')
  end

  def delete_step_results
    step_results.destroy_all
  end

  private

  # Override for ObservableModel
  def changed_by
    last_modified_by || user
  end
end
