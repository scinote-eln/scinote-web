class Sample < ActiveRecord::Base
  include SearchableModel

  auto_strip_attributes :name, nullify: false
  validates :name,
            presence: true,
            length: { maximum: Constants::NAME_MAX_LENGTH }
  validates :user, :team, presence: true

  belongs_to :user, inverse_of: :samples
  belongs_to :last_modified_by, foreign_key: 'last_modified_by_id', class_name: 'User'
  belongs_to :team, inverse_of: :samples
  belongs_to :sample_group, inverse_of: :samples
  belongs_to :sample_type, inverse_of: :samples
  has_many :sample_my_modules, inverse_of: :sample, dependent: :destroy
  has_many :my_modules, through: :sample_my_modules
  has_many :sample_comments, inverse_of: :sample, dependent: :destroy
  has_many :comments, through: :sample_comments, dependent: :destroy
  has_many :sample_custom_fields, inverse_of: :sample, dependent: :destroy
  has_many :custom_fields, through: :sample_custom_fields

  def self.search(
    user,
    include_archived,
    query = nil,
    page = 1,
    current_team = nil
  )
    team_ids = Team.joins(:user_teams)
                   .where('user_teams.user_id = ?', user.id)
                   .select('id')
                   .distinct

    if query
      a_query = '%' + query.strip.gsub('_', '\\_').gsub('%', '\\%') + '%'
    else
      a_query = query
    end

    if current_team
      new_query = Sample
                  .distinct
                  .where('samples.team_id = ?', current_team.id)
                  .where_attributes_like(['samples.name'], a_query)

      return new_query
    else
      new_query = Sample
                  .distinct
                  .joins(:user)
                  .joins('LEFT OUTER JOIN sample_types ON ' \
                         'samples.sample_type_id = sample_types.id')
                  .joins('LEFT OUTER JOIN sample_groups ON ' \
                         'samples.sample_group_id = sample_groups.id')
                  .joins('LEFT OUTER JOIN sample_custom_fields ON ' \
                         'samples.id = sample_custom_fields.sample_id')
                  .where('samples.team_id IN (?)', team_ids)
                  .where_attributes_like(
                    [
                      'samples.name',
                      'sample_types.name',
                      'sample_groups.name',
                      'users.full_name',
                      'sample_custom_fields.value'
                    ],
                    a_query
                  )
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
