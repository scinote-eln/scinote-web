class RepositoryRow < ApplicationRecord
  include SearchableModel

  belongs_to :repository, optional: true
  belongs_to :created_by,
             foreign_key: :created_by_id,
             class_name: 'User',
             optional: true
  belongs_to :last_modified_by,
             foreign_key: :last_modified_by_id,
             class_name: 'User',
             optional: true
  has_many :repository_cells, dependent: :destroy
  has_many :repository_columns, through: :repository_cells
  has_many :my_module_repository_rows,
           inverse_of: :repository_row, dependent: :destroy
  has_many :my_modules, through: :my_module_repository_rows

  auto_strip_attributes :name, nullify: false
  validates :name,
            presence: true,
            length: { maximum: Constants::NAME_MAX_LENGTH }
  validates :created_by, presence: true

  def self.search(repository, query, page = 1, options)
    new_query = distinct
                .joins(:created_by)
                .joins(
                  "LEFT OUTER JOIN (
                  SELECT repository_cells.repository_row_id,
                  repository_text_values.data AS text_value,
                  to_char(repository_date_values.data, 'DD.MM.YYYY HH24:MI')
                  AS date_value
                  FROM repository_cells
                  INNER JOIN repository_text_values
                  ON repository_text_values.id = repository_cells.value_id
                  FULL OUTER JOIN repository_date_values
                  ON repository_date_values.id = repository_cells.value_id
                  ) AS values
                  ON values.repository_row_id = repository_rows.id"
                )
                .where_attributes_like(
                  ['repository_rows.name', 'users.full_name',
                   'values.text_value', 'values.date_value'],
                  query, options
                )

    if repository
      new_query = new_query
                  .preload(
                    :repository_columns,
                    :created_by,
                    repository_cells: :value
                  )
                  .where(repository: repository)
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
