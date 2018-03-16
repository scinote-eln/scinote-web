class Repository < ApplicationRecord
  include SearchableModel

  belongs_to :team, optional: true
  belongs_to :created_by,
             foreign_key: :created_by_id,
             class_name: 'User',
             optional: true
  has_many :repository_columns
  has_many :repository_rows
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

  def self.search(
    user,
    query = nil,
    page = 1,
    repository = nil,
    options = {}
  )
    repositories = repository ? repository : Repository.where(team: user.teams)

    includes_json = { repository_cells: Extends::REPOSITORY_SEARCH_INCLUDES }
    searchable_attributes = ['repository_rows.name', 'users.full_name'] +
                            Extends::REPOSITORY_EXTRA_SEARCH_ATTR

    new_query = RepositoryRow
                .left_outer_joins(:created_by)
                .left_outer_joins(includes_json)
                .where(repository: repositories)
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
        .distinct
        .limit(Constants::SEARCH_LIMIT)
        .offset((page - 1) * Constants::SEARCH_LIMIT)
    end
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

  # Imports records
  def import_records(sheet, mappings, user)
    errors = false
    columns = []
    name_index = -1
    total_nr = 0
    nr_of_added = 0
    header_skipped = false

    mappings.each.with_index do |(_k, value), index|
      if value == '-1'
        # Fill blank space, so our indices stay the same
        columns << nil
        name_index = index
      else
        columns << repository_columns.find_by_id(value)
      end
    end

    # Check for duplicate columns
    col_compact = columns.compact
    unless col_compact.map(&:id).uniq.length == col_compact.length
      return { status: :error, nr_of_added: nr_of_added, total_nr: total_nr }
    end
    rows = SpreadsheetParser.spreadsheet_enumerator(sheet)

    # Now we can iterate through record data and save stuff into db
    rows.each do |row|
      # Skip empty rows
      next if row.empty?
      unless header_skipped
        header_skipped = true
        next
      end
      total_nr += 1

      row = SpreadsheetParser.parse_row(row, sheet)

      record_row = RepositoryRow.new(name: row[name_index],
                                 repository: self,
                                 created_by: user,
                                 last_modified_by: user)
      record_row.transaction do
        unless record_row.save
          errors = true
          raise ActiveRecord::Rollback
        end

        row_cell_values = []

        row.each.with_index do |value, index|
          if columns[index] && value
            cell_value = RepositoryTextValue.new(
              data: value,
              created_by: user,
              last_modified_by: user,
              repository_cell_attributes: {
                repository_row: record_row,
                repository_column: columns[index]
              }
            )
            unless cell_value.valid?
              errors = true
              raise ActiveRecord::Rollback
            end
            row_cell_values << cell_value
          end
        end
        if RepositoryTextValue.import(row_cell_values,
                                      recursive: true,
                                      validate: false).failed_instances.any?
          errors = true
          raise ActiveRecord::Rollback
        end
        nr_of_added += 1
      end
    end

    if errors
      return { status: :error, nr_of_added: nr_of_added, total_nr: total_nr }
    end
    { status: :ok, nr_of_added: nr_of_added, total_nr: total_nr }
  end
end
