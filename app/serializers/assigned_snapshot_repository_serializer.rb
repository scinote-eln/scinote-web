# frozen_string_literal: true

class AssignedSnapshotRepositorySerializer < ActiveModel::Serializer
  attributes :id, :name, :created_by, :status

  def name
    I18n.t('my_modules.repository.version.snapshot_name', snapshot_date: I18n.l(object.created_at, format: :full))
  end

  def created_by
    object.created_by.full_name
  end
end
