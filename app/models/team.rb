# frozen_string_literal: true

class Team < ApplicationRecord
  include SearchableModel
  include ViewableModel
  include Assignable
  include PermissionCheckableModel
  include TeamBySubjectModel
  include TinyMceImages

  # Not really MVC-compliant, but we just use it for logger
  # output in space_taken related functions
  include ActionView::Helpers::NumberHelper

  after_create :generate_template_project
  after_create :create_default_label_templates
  scope :teams_select, -> { select(:id, :name).order(name: :asc) }
  scope :ordered, -> { order('LOWER(name)') }

  auto_strip_attributes :name, :description, nullify: false
  validates :name,
            length: { minimum: Constants::NAME_MIN_LENGTH,
                      maximum: Constants::NAME_MAX_LENGTH }
  validates :description, length: { maximum: Constants::TEXT_MAX_LENGTH }

  belongs_to :created_by,
             foreign_key: 'created_by_id',
             class_name: 'User',
             optional: true
  belongs_to :last_modified_by,
             foreign_key: 'last_modified_by_id',
             class_name: 'User',
             optional: true
  has_many :user_teams, inverse_of: :team, dependent: :destroy
  has_many :users, through: :user_assignments
  has_many :projects, inverse_of: :team
  has_many :project_folders, inverse_of: :team, dependent: :destroy
  has_many :protocols, inverse_of: :team, dependent: :destroy
  has_many :repository_protocols,
           (lambda do
             where(protocol_type: [Protocol.protocol_types[:in_repository_public],
                                   Protocol.protocol_types[:in_repository_private],
                                   Protocol.protocol_types[:in_repository_archived]])
           end),
           class_name: 'Protocol'
  has_many :protocol_keywords, inverse_of: :team, dependent: :destroy
  has_many :tiny_mce_assets, inverse_of: :team, dependent: :destroy
  has_many :repositories, dependent: :destroy
  has_many :reports, inverse_of: :team, dependent: :destroy
  has_many :activities, inverse_of: :team, dependent: :destroy
  has_many :assets, inverse_of: :team, dependent: :destroy
  has_many :label_templates, dependent: :destroy
  has_many :team_shared_objects, inverse_of: :team, dependent: :destroy
  has_many :team_shared_repositories,
           -> { where(shared_object_type: 'RepositoryBase') },
           class_name: 'TeamSharedObject',
           inverse_of: :team
  has_many :shared_repositories, through: :team_shared_objects, source: :shared_object, source_type: 'RepositoryBase'
  has_many :repository_sharing_user_assignments,
           (lambda do |team|
             joins(
               "INNER JOIN repositories "\
               "ON user_assignments.assignable_type = 'RepositoryBase' "\
               "AND user_assignments.assignable_id = repositories.id"
             ).where(team_id: team.id)
             .where.not('user_assignments.team_id = repositories.team_id')
           end),
           class_name: 'UserAssignment'
  has_many :shared_by_user_repositories,
           through: :repository_sharing_user_assignments,
           source: :assignable,
           source_type: 'RepositoryBase'

  attr_accessor :without_templates

  def default_view_state
    {
      projects: {
        active: { sort: 'new' },
        archived: { sort: 'new' },
        view_type: 'cards'
      }
    }
  end

  def validate_view_state(view_state)
    if %w(new old atoz ztoa id_asc id_desc).exclude?(view_state.state.dig('projects', 'active', 'sort')) ||
       %w(new old atoz ztoa id_asc id_desc archived_new archived_old).exclude?(view_state.state.dig('projects', 'archived', 'sort')) ||
       %w(cards table).exclude?(view_state.state.dig('projects', 'view_type'))
      view_state.errors.add(:state, :wrong_state)
    end
  end

  def search_users(query = nil)
    a_query = "%#{query}%"
    users.where.not(confirmed_at: nil)
         .where('full_name ILIKE ? OR email ILIKE ?', a_query, a_query)
  end

  def storage_used
    by_assets = Asset.joins(:file_blob)
                     .where(assets: { team_id: id })
                     .select('active_storage_blobs.byte_size')

    by_tiny_mce_assets = TinyMceAsset.joins(:image_blob)
                                     .where(tiny_mce_assets: { team_id: id })
                                     .select('active_storage_blobs.byte_size')

    ActiveStorage::Blob
      .from("((#{by_assets.to_sql}) UNION ALL (#{by_tiny_mce_assets.to_sql})) AS active_storage_blobs")
      .sum(:byte_size)
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
      when 'StepText'
        obj.step.protocol.team_id
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

  def create_default_label_templates
    ZebraLabelTemplate.default.update(team: self, default: true)
    FluicsLabelTemplate.default.update(team: self, default: true)
  end
end
