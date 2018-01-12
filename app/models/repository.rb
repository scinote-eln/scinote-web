class Repository < ActiveRecord::Base
  include SearchableModel

  belongs_to :team
  belongs_to :created_by, foreign_key: :created_by_id, class_name: 'User'
  has_many :repository_columns
  has_many :repository_rows
  has_many :repository_table_states,
           inverse_of: :repository, dependent: :destroy
  has_many :report_elements, inverse_of: :repository, dependent: :destroy

  auto_strip_attributes :name, nullify: false
  validates :name,
            presence: true,
            uniqueness: { scope: :team, case_sensitive: false },
            length: { maximum: Constants::NAME_MAX_LENGTH }
  validates :team, presence: true
  validates :created_by, presence: true

  def self.search(
    user,
    _include_archived,
    query = nil,
    page = 1,
    current_team = nil,
    options = {}
  )
    team_ids =
      if current_team
        current_team.id
      else
        Team.joins(:user_teams)
            .where('user_teams.user_id = ?', user.id)
            .distinct
            .pluck(:id)
      end

    row_ids = RepositoryRow
              .search(nil, query, Constants::SEARCH_NO_LIMIT, options)
              .select(:id)

    new_query = Repository
                .select('repositories.*, COUNT(repository_rows.id) AS counter')
                .joins(:team)
                .joins('LEFT OUTER JOIN repository_rows ON ' \
                       'repositories.id = repository_rows.repository_id')
                .where(team: team_ids)
                .where('repository_rows.id IN (?)', row_ids)
                .group('repositories.id')

    # Show all results if needed
    if page == Constants::SEARCH_NO_LIMIT
      new_query
    else
      new_query
        .limit(Constants::SEARCH_LIMIT)
        .offset((page - 1) * Constants::SEARCH_LIMIT)
    end
  end

  def available_repository_fields
    fields = {}
    # First and foremost add record name
    fields['-1'] = I18n.t('repositories.default_column')
    # Add all other custom columns
    repository_columns.order(:created_at).each do |rc|
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
            cell = RepositoryCell.new(repository_row: record_row,
                                      repository_column: columns[index],
                                      value: cell_value)
            cell.skip_on_import = true
            cell_value.repository_cell = cell
            unless cell.valid? && cell_value.valid?
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
