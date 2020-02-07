# frozen_string_literal: true

class Team < ApplicationRecord
  include SearchableModel
  include ViewableModel
  include TeamBySubjectModel
  include TinyMceImages

  # Not really MVC-compliant, but we just use it for logger
  # output in space_taken related functions
  include ActionView::Helpers::NumberHelper

  after_create :generate_template_project
  scope :teams_select, -> { select(:id, :name).order(name: :asc) }
  scope :ordered, -> { order('LOWER(name)') }

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
  has_many :samples, inverse_of: :team
  has_many :samples_tables, inverse_of: :team, dependent: :destroy
  has_many :sample_groups, inverse_of: :team
  has_many :sample_types, inverse_of: :team
  has_many :projects, inverse_of: :team
  has_many :custom_fields, inverse_of: :team
  has_many :protocols, inverse_of: :team, dependent: :destroy
  has_many :protocol_keywords, inverse_of: :team, dependent: :destroy
  has_many :tiny_mce_assets, inverse_of: :team, dependent: :destroy
  has_many :repositories, dependent: :destroy
  has_many :reports, inverse_of: :team, dependent: :destroy
  has_many :activities, inverse_of: :team, dependent: :destroy
  has_many :assets, inverse_of: :team, dependent: :destroy
  has_many :team_repositories, inverse_of: :team, dependent: :destroy
  has_many :shared_repositories, through: :team_repositories, source: :repository

  attr_accessor :without_templates
  attr_accessor :without_intro_demo
  after_create :generate_intro_demo

  def default_view_state
    { 'projects' =>
      { 'cards' => { 'sort' => 'new' },
        'table' =>
          { 'time' => Time.now.to_i,
            'order' => [[2, 'asc']],
            'start' => 0,
            'length' => 10 },
        'filter' => 'active' } }
  end

  def validate_view_state(view_state)
    unless %w(new old atoz ztoa).include?(view_state.state.dig('projects', 'cards', 'sort')) &&
           %w(all active archived).include?(view_state.state.dig('projects', 'filter'))
      view_state.errors.add(:state, :wrong_state)
    end
  end

  def search_users(query = nil)
    a_query = "%#{query}%"
    users.where.not(confirmed_at: nil)
         .where('full_name ILIKE ? OR email ILIKE ?', a_query, a_query)
  end

  def to_csv(samples, headers)
    require "csv"

    # Parse headers (magic numbers should be refactored - see
    # sample-datatable.js)
    header_names = []
    headers.each do |header|
      if header == "-1"
        header_names << I18n.t("samples.table.sample_name")
      elsif header == "-2"
        header_names << I18n.t("samples.table.sample_type")
      elsif header == "-3"
        header_names << I18n.t("samples.table.sample_group")
      elsif header == "-4"
        header_names << I18n.t("samples.table.added_by")
      elsif header == "-5"
        header_names << I18n.t("samples.table.added_on")
      else
        cf = CustomField.find_by_id(header)

        if cf
          header_names << cf.name
        else
          header_names << nil
        end
      end
    end

    CSV.generate do |csv|
      csv << header_names
      samples.each do |sample|
        sample_row = []
        headers.each do |header|
          if header == "-1"
            sample_row << sample.name
          elsif header == "-2"
            sample_row << (sample.sample_type.nil? ? I18n.t("samples.table.no_type") : sample.sample_type.name)
          elsif header == "-3"
            sample_row << (sample.sample_group.nil? ? I18n.t("samples.table.no_group") : sample.sample_group.name)
          elsif header == "-4"
            sample_row << sample.user.full_name
          elsif header == "-5"
            sample_row << I18n.l(sample.created_at, format: :full)
          else
            scf = SampleCustomField.where(
              custom_field_id: header,
              sample_id: sample.id
            ).take

            if scf
              sample_row << scf.value
            else
              sample_row << nil
            end
          end
        end
        csv << sample_row
      end
    end
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

  def self.global_activity_filter(filters, search_query)
    query = where('name ILIKE ?', "%#{search_query}%")
    if filters[:users]
      users_team = User.where(id: filters[:users]).joins(:user_teams).group(:team_id).pluck(:team_id)
      query = query.where(id: users_team)
    end
    query = query.where(id: team_by_subject(filters[:subjects])) if filters[:subjects]
    query.select(:id, :name).map { |i| { value: i[:id], label: ApplicationController.helpers.escape_input(i[:name]) } }
  end

  def self.search_by_object(obj)
    find(
      case obj.class.name
      when 'Protocol'
        obj.team_id
      when 'MyModule', 'Step'
        obj.protocol.team_id
      when 'ResultText'
        obj.result.my_module.protocol.team_id
      end
    )
  end

  private

  def generate_template_project
    return if without_templates
    TemplatesService.new.delay(queue: :templates).update_team(self)
  end

  include FirstTimeDataGenerator

  def generate_intro_demo
    return if without_intro_demo

    user = User.find(created_by_id)
    if user.created_teams.order(:created_at).first == self
      seed_demo_data(user, self)
    end
  end
end
