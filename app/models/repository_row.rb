# frozen_string_literal: true

class RepositoryRow < ApplicationRecord
  include SearchableModel
  include SearchableByNameModel
  include ArchivableModel

  belongs_to :repository, class_name: 'RepositoryBase'
  belongs_to :created_by, foreign_key: :created_by_id, class_name: 'User'
  belongs_to :last_modified_by, foreign_key: :last_modified_by_id, class_name: 'User'
  belongs_to :archived_by,
             foreign_key: :archived_by_id,
             class_name: 'User',
             inverse_of: :archived_repository_rows,
             optional: true
  belongs_to :restored_by,
             foreign_key: :archived_by_id,
             class_name: 'User',
             inverse_of: :restored_repository_rows,
             optional: true
  has_many :repository_cells, -> { order(:id) }, dependent: :destroy
  has_many :repository_columns, through: :repository_cells
  has_many :my_module_repository_rows,
           inverse_of: :repository_row, dependent: :destroy
  has_many :my_modules, through: :my_module_repository_rows

  auto_strip_attributes :name, nullify: false
  validates :name,
            presence: true,
            length: { maximum: Constants::NAME_MAX_LENGTH }
  validates :created_by, presence: true
  # with_options if: :archived do
  #   validates :archived_by, presence: true
  #   validates :archived_on, presence: true
  # end

  scope :active, -> { where(archived: false) }
  scope :archived, -> { where(archived: true) }

  def self.viewable_by_user(user, teams)
    where(repository: Repository.viewable_by_user(user, teams))
  end

  def self.name_like(query)
    where('repository_rows.name ILIKE ?', "%#{query}%")
  end

  def self.change_owner(team, user, new_owner)
    joins(:repository)
      .where('repositories.team_id = ? and repository_rows.created_by_id = ?', team, user)
      .update_all(created_by_id: new_owner.id)
  end

  def editable?
    true
  end

  def snapshot!(repository_snapshot)
    row_snapshot = dup
    row_snapshot.assign_attributes(
      repository: repository_snapshot,
      parent_id: id,
      created_at: created_at,
      updated_at: updated_at
    )
    row_snapshot.save!

    repository_cells.each { |cell| cell.snapshot!(row_snapshot) }
  end
end
