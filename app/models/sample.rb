# frozen_string_literal: true

class Sample < ApplicationRecord
  include SearchableModel

  auto_strip_attributes :name, nullify: false
  validates :name,
            presence: true,
            length: { maximum: Constants::NAME_MAX_LENGTH }
  validates :user, :team, presence: true

  belongs_to :user, inverse_of: :samples
  belongs_to :last_modified_by, foreign_key: 'last_modified_by_id', class_name: 'User', optional: true
  belongs_to :team, inverse_of: :samples
  belongs_to :sample_group, inverse_of: :samples, optional: true
  belongs_to :sample_type, inverse_of: :samples, optional: true
  has_many :sample_my_modules, inverse_of: :sample, dependent: :destroy
  has_many :my_modules, through: :sample_my_modules
  has_many :sample_custom_fields, inverse_of: :sample, dependent: :destroy
  has_many :custom_fields, through: :sample_custom_fields

  def self.search(
    user,
    _include_archived,
    query = nil,
    page = 1,
    current_team = nil,
    options = {}
  )
    team_ids = Team.joins(:user_teams)
                   .where('user_teams.user_id = ?', user.id)
                   .distinct
                   .pluck(:id)

    if current_team
      new_query = Sample
                  .distinct
                  .where('samples.team_id = ?', current_team.id)
                  .where_attributes_like(['samples.name'], query, options)

      return new_query
    else
      user_ids = User
                 .joins(:user_teams)
                 .where('user_teams.team_id IN (?)', team_ids)
                 .where_attributes_like(['users.full_name'], query, options)
                 .pluck(:id)

      sample_ids = Sample
                   .joins(:user)
                   .where('team_id IN (?)', team_ids)
                   .where_attributes_like(['name'], query, options)
                   .pluck(:id)

      sample_type_ids = SampleType
                        .where('team_id IN (?)', team_ids)
                        .where_attributes_like(['name'], query, options)
                        .pluck(:id)

      sample_group_ids = SampleGroup
                         .where('team_id IN (?)', team_ids)
                         .where_attributes_like(['name'], query, options)
                         .pluck(:id)

      sample_custom_fields = SampleCustomField
                             .joins(:sample)
                             .where('samples.team_id IN (?)', team_ids)
                             .where_attributes_like(['value'], query, options)
                             .pluck(:id)
      new_query = Sample
                  .distinct
                  .joins(:user)
                  .joins('LEFT OUTER JOIN sample_types ON ' \
                         'samples.sample_type_id = sample_types.id')
                  .joins('LEFT OUTER JOIN sample_groups ON ' \
                         'samples.sample_group_id = sample_groups.id')
                  .joins('LEFT OUTER JOIN sample_custom_fields ON ' \
                         'samples.id = sample_custom_fields.sample_id')
                  .where('samples.user_id IN (?) OR samples.id IN (?) ' \
                         'OR sample_types.id IN (?) ' \
                         'OR sample_groups.id IN (?)' \
                         'OR sample_custom_fields.id IN (?)',
                         user_ids, sample_ids, sample_type_ids,
                         sample_group_ids, sample_custom_fields)
    end
    # Show all results if needed
    if page == Constants::SEARCH_NO_LIMIT
      new_query
    else
      new_query
        .limit(Constants::SEARCH_LIMIT)
        .offset((page - 1) * Constants::SEARCH_LIMIT)
    end
  end
end
