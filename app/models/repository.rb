class Repository < ActiveRecord::Base
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

  def open_spreadsheet(file)
    filename = file.original_filename
    file_path = file.path

    if file.class == Paperclip::Attachment && file.is_stored_on_s3?
      fa = file.fetch
      file_path = fa.path
    end
    generate_file(filename, file_path)
  end

  def available_repository_fields
    fields = {}
    # First and foremost add sample name
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
    errors = []
    custom_fields = []
    name_index = -1
    nr_of_added = 0

    mappings.each.with_index do |(k, v), i|
      if v == '-1'
        # Fill blank space, so our indices stay the same
        custom_fields << nil
        name_index = i
      else
        cf = repository_columns.find_by_id(v)
        custom_fields << cf
      end
    end

    # Now we can iterate through sample data and save stuff into db
    (2..sheet.last_row).each do |i|
      error = []
      nr_of_added += 1
      record_row = RepositoryRow.new(name: sheet.row(i)[name_index],
                                 repository: self,
                                 created_by: user,
                                 last_modified_by: user)

      if record_row.save
        sheet.row(i).each.with_index do |value, index|
          if custom_fields[index]
            # we're working with CustomField
            rep_column = RepositoryTextValue.new(
              data: value,
              created_by: user,
              last_modified_by: user,
              repository_cell_attributes: {
                repository_row: record_row,
                repository_column: custom_fields[index]
              }
            )

            if !rep_column.save
              error << rep_column.errors.messages
            end
          else
            # This custom_field does not exist
            error << { '#{mappings[index]}': 'Does not exists' }
          end
        end
      end
    end

    if errors.count > 0
      return { status: :error, errors: errors, nr_of_added: nr_of_added }
    end
    { status: :ok, nr_of_added: nr_of_added }
  end

  private

  # def generate_new_columns(header)
  #   rep_columns_names = self.repository_columns.pluck(:name).push('Name')
  #   header.each do |cname|
  #     next if rep_columns_names.include? cname
  #     RepositoryColumn.create(repository: self, name: cname, data_type: 0)
  #   end
  # end

  def generate_file(filename, file_path)
    case File.extname(filename)
    when '.csv'
      Roo::CSV.new(file_path, extension: :csv)
    when '.tdv'
      Roo::CSV.new(file_path, nil, :ignore, csv_options: { col_sep: '\t' })
    when '.txt'
      # This assumption is based purely on biologist's habits
      Roo::CSV.new(file_path, csv_options: { col_sep: '\t' })
    when '.xls'
      Roo::Excel.new(file_path)
    when '.xlsx'
      Roo::Excelx.new(file_path)
    else
      raise TypeError
    end
  end
end
