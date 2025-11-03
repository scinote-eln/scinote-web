# frozen_string_literal: true

class ResultBase < ApplicationRecord
  include SearchableModel
  include SearchableByNameModel
  include ViewableModel
  include Discard::Model

  self.table_name = 'results'

  default_scope -> { kept }

  auto_strip_attributes :name, nullify: false
  validates :name, length: { maximum: Constants::NAME_MAX_LENGTH }

  SEARCHABLE_ATTRIBUTES = ['results.name', :children].freeze

  enum assets_view_mode: { thumbnail: 0, list: 1, inline: 2 }

  belongs_to :user, inverse_of: :results
  belongs_to :last_modified_by, class_name: 'User', optional: true
  has_many :result_orderable_elements, inverse_of: :result, dependent: :destroy
  has_many :result_assets, inverse_of: :result, dependent: :destroy
  has_many :assets, through: :result_assets, dependent: :destroy
  has_many :result_tables, inverse_of: :result, dependent: :destroy
  has_many :tables, through: :result_tables, dependent: :destroy
  has_many :result_texts, inverse_of: :result, dependent: :destroy
  has_many :step_results, dependent: :destroy, inverse_of: :result
  has_many :steps, through: :step_results

  before_save :ensure_default_name
  after_discard :delete_step_results
  after_discard do
    CleanupUserSettingsJob.perform_later('result_states', id)
  end

  def self.find_page_number(result_id, per_page = Kaminari.config.default_per_page)
    position = pluck(:id).index(result_id)
    (position.to_f / per_page).ceil
  end

  def duplicate(object, user, result_name: nil)
    ActiveRecord::Base.transaction do
      target_object = if object.is_a?(Protocol) && object.in_module?
                        object.my_module
                      else
                        object
                      end

      new_result = target_object.results.new(
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

      ResultBase.delay(queue: :assets).deep_clone_assets(assets_to_clone)

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
    view_state.errors.add(:state, :wrong_state) unless %w(new old atoz ztoa).include?(view_state.state.dig('assets', 'sort'))
  end

  def space_taken
    result_assets.joins(asset: { file_attachment: :blob }).sum('active_storage_blobs.byte_size')
  end

  def unlocked?(result)
    result.assets.none?(&:locked?)
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
end
