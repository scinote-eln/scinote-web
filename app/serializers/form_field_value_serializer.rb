# frozen_string_literal: true

class FormFieldValueSerializer < ActiveModel::Serializer
  include Canaid::Helpers::PermissionsHelper

  attributes :id, :form_field_id, :type, :value, :submitted_at, :submitted_by_full_name,
             :unit, :not_applicable, :selection, :datetime, :datetime_to

  def submitted_by_full_name
    object.submitted_by.full_name
  end

  def submitted_at
    I18n.l(object.submitted_at, format: :full) if object.submitted_at
  end

  def value
    if object.type == 'FormRepositoryRowsFieldValue'
      object.value.map do |value|
        row_code = "#{RepositoryRow::ID_PREFIX}#{value['id']}"
        repository = Repository.find_by(id: value['repository_id'])

        value[:has_access] = repository.nil? || can_read_repository?(scope[:user], repository)
        value[:name] = if value[:has_access]
                         "#{value['name']} (#{row_code})"
                       else
                         I18n.t('my_modules.assigned_items.repository.private_repository_row_name', repository_row_code: "#{RepositoryRow::ID_PREFIX}#{value['id']}")
                       end
        value
      end
    else
      object.value
    end
  end
end
