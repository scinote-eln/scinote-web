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
    fields['-1'] = I18n.t('samples.table.sample_name')
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

  private

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
