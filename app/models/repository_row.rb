# frozen_string_literal: true

class RepositoryRow < ApplicationRecord
  include SearchableModel
  include SearchableByNameModel

  belongs_to :repository, optional: true
  belongs_to :created_by, foreign_key: :created_by_id, class_name: 'User'
  belongs_to :last_modified_by, foreign_key: :last_modified_by_id, class_name: 'User'
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

  def self.viewable_by_user(user, teams)
    where(repository: Repository.viewable_by_user(user, teams))
  end

  def self.assigned_on_my_module(ids, my_module)
    where(id: ids).joins(:my_module_repository_rows)
                  .where('my_module_repository_rows.my_module' => my_module)
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
end
