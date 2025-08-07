# frozen_string_literal: true

module FormFieldValuesHelper
  include Canaid::Helpers::PermissionsHelper

  def form_repository_rows_field_value_formatter(field_values, user = current_user)
    field_values&.value&.map do |value|
      row_code = "#{RepositoryRow::ID_PREFIX}#{value['id']}"
      repository = Repository.find_by(id: value['repository_id'])

      if repository.nil? || can_read_repository?(user, repository)
        "#{value['name']} (#{row_code})"
      else
        I18n.t('my_modules.assigned_items.repository.private_repository_row_name', repository_row_code: row_code)
      end
    end&.join(' | ')
  end
end
