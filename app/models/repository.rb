class Repository < ApplicationRecord
  include SearchableModel
  include RepositoryImportParser
  include Discard::Model

  attribute :discarded_by_id, :integer

  belongs_to :team, optional: true
  belongs_to :created_by,
             foreign_key: :created_by_id,
             class_name: 'User',
             optional: true
  has_many :repository_columns, dependent: :destroy
  has_many :repository_rows, dependent: :destroy
  has_many :repository_table_states,
           inverse_of: :repository, dependent: :destroy
  has_many :report_elements, inverse_of: :repository, dependent: :destroy
  has_many :repository_list_items, inverse_of: :repository, dependent: :destroy

  auto_strip_attributes :name, nullify: false
  validates :name,
            presence: true,
            uniqueness: { scope: :team, case_sensitive: false },
            length: { maximum: Constants::NAME_MAX_LENGTH }
  validates :team, presence: true
  validates :created_by, presence: true

  default_scope -> { kept }

  def self.search(
    user,
    query = nil,
    page = 1,
    repository = nil,
    options = {}
  )
    repositories = repository || Repository.where(team: user.teams)

    includes_json = { repository_cells: Extends::REPOSITORY_SEARCH_INCLUDES }
    searchable_attributes = ['repository_rows.name', 'users.full_name'] +
                            Extends::REPOSITORY_EXTRA_SEARCH_ATTR

    all_rows = RepositoryRow.where(repository: repositories)

    new_query = RepositoryRow
                .distinct
                .from(all_rows, 'repository_rows')
                .left_outer_joins(:created_by)
                .left_outer_joins(includes_json)
                .where_attributes_like(searchable_attributes, query, options)

    # Show all results if needed
    if page == Constants::SEARCH_NO_LIMIT
      new_query
        .joins(:repository)
        .select(
          'repositories.id AS id, COUNT(DISTINCT repository_rows.id) AS counter'
        )
        .group('repositories.id')
    else
      new_query
        .limit(Constants::SEARCH_LIMIT)
        .offset((page - 1) * Constants::SEARCH_LIMIT)
    end
  end

  def self.name_like(query)
    where('repositories.name ILIKE ?', "%#{query}%")
  end

  def available_columns_ids
    repository_columns.pluck(:id)
  end

  def importable_repository_fields
    fields = {}
    # First and foremost add record name
    fields['-1'] = I18n.t('repositories.default_column')
    # Add all other custom columns
    repository_columns.order(:created_at).each do |rc|
      next unless rc.importable?
      fields[rc.id] = rc.name
    end
    fields
  end

  def copy(created_by, name)
    new_repo = nil

    begin
      Repository.transaction do
        # Clone the repository object
        new_repo = dup
        new_repo.created_by = created_by
        new_repo.name = name
        new_repo.save!

        # Clone columns (only if new_repo was saved)
        repository_columns.find_each do |col|
          new_col = col.dup
          new_col.repository = new_repo
          new_col.created_by = created_by
          new_col.save!
        end
      end
    rescue ActiveRecord::RecordInvalid
      return false
    end

    # If everything is okay, return new_repo
    new_repo
  end

  def import_records(sheet, mappings, user)
    importer = RepositoryImportParser::Importer.new(sheet, mappings, user, self)
    importer.run
  end

  def destroy_discarded(discarded_by_id = nil)
    self.discarded_by_id = discarded_by_id
    destroy
  end
  handle_asynchronously :destroy_discarded,
                        queue: :clear_discarded_repository,
                        priority: 20
end
