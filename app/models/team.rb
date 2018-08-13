class Team < ApplicationRecord
  include SearchableModel

  # Not really MVC-compliant, but we just use it for logger
  # output in space_taken related functions
  include ActionView::Helpers::NumberHelper

  auto_strip_attributes :name, :description, nullify: false
  validates :name,
            length: { minimum: Constants::NAME_MIN_LENGTH,
                      maximum: Constants::NAME_MAX_LENGTH }
  validates :description, length: { maximum: Constants::TEXT_MAX_LENGTH }
  validates :space_taken, presence: true

  belongs_to :created_by,
             foreign_key: 'created_by_id',
             class_name: 'User',
             optional: true
  belongs_to :last_modified_by,
             foreign_key: 'last_modified_by_id',
             class_name: 'User',
             optional: true
  has_many :user_teams, inverse_of: :team, dependent: :destroy
  has_many :users, through: :user_teams
  has_many :projects, inverse_of: :team
  has_many :custom_fields, inverse_of: :team
  has_many :protocols, inverse_of: :team, dependent: :destroy
  has_many :protocol_keywords, inverse_of: :team, dependent: :destroy
  has_many :tiny_mce_assets, inverse_of: :team, dependent: :destroy
  has_many :repositories, dependent: :destroy
  has_many :reports, inverse_of: :team, dependent: :destroy
  has_many :datatables_reports,
           class_name: 'Views::Datatables::DatatablesReport'

  after_commit do
    Views::Datatables::DatatablesReport.refresh_materialized_view
  end

  def search_users(query = nil)
    a_query = "%#{query}%"
    users.where.not(confirmed_at: nil)
         .where('full_name ILIKE ? OR email ILIKE ?', a_query, a_query)
  end

  # Get all header fields for samples (used in importing for mappings - dropdowns)
  def get_available_sample_fields
    fields = {};

    # First and foremost add sample name
    fields["-1"] = I18n.t("samples.table.sample_name")
    fields["-2"] = I18n.t("samples.table.sample_type")
    fields["-3"] = I18n.t("samples.table.sample_group")

    # Add all other custom fields
    CustomField.where(team_id: id).order(:created_at).each do |cf|
      fields[cf.id] = cf.name
    end

    fields
  end

  # (re)calculate the space taken by this team
  def calculate_space_taken
    st = 0
    projects.includes(
      experiments: {
        my_modules: {
          protocols: { steps: :assets },
          results: { result_asset: :asset }
        }
      }
    ).find_each do |project|
      project.project_my_modules.find_each do |my_module|
        my_module.protocol.steps.find_each do |step|
          step.assets.find_each { |asset| st += asset.estimated_size }
          step.tiny_mce_assets.find_each { |tiny| st += tiny.estimated_size }
        end
        my_module.results.find_each do |result|
          st += result.asset.estimated_size if result.is_asset
          if result.is_text
            tiny_assets = TinyMceAsset.where(result_text: result.result_text)
            tiny_assets.find_each { |tiny| st += tiny.estimated_size }
          end
        end
      end
    end
    # project.experiments.each |experiment|
    self.space_taken = [st, Constants::MINIMAL_TEAM_SPACE_TAKEN].max
    Rails::logger.info "Team #{self.id}: " +
      "space (re)calculated to: " +
      "#{self.space_taken}B (#{number_to_human_size(self.space_taken)})"
  end

  # Take specified amount of bytes
  def take_space(space)
    orig_space = self.space_taken
    self.space_taken += space
    Rails::logger.info "Team #{self.id}: " +
      "space taken: " +
      "#{orig_space}B + #{space}B = " +
      "#{self.space_taken}B (#{number_to_human_size(self.space_taken)})"
  end

  # Release specified amount of bytes
  def release_space(space)
    orig_space = self.space_taken
    self.space_taken = [space_taken - space,
                        Constants::MINIMAL_TEAM_SPACE_TAKEN].max
    Rails::logger.info "Team #{self.id}: " +
      "space released: " +
      "#{orig_space}B - #{space}B = " +
      "#{self.space_taken}B (#{number_to_human_size(self.space_taken)})"
  end

  def protocol_keywords_list
    ProtocolKeyword.where(team: self).pluck(:name)
  end
end
