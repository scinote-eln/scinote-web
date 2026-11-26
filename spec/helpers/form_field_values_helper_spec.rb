# frozen_string_literal: true

require 'rails_helper'

describe FormFieldValuesHelper, type: :helper do
  describe '#form_repository_rows_field_value_formatter' do
    let(:user) { create :user }
    let(:team) { create :team, created_by: user }
    let(:repository) { create :repository, team: team, created_by: user }
    let(:other_repository) { create :repository }

    def field_value(*rows)
      FormRepositoryRowsFieldValue.new(data: rows)
    end

    before do
      user.update!(current_team_id: team.id)
      create_user_assignment(repository, UserRole.find_by(name: I18n.t('user_roles.predefined.owner')), user)
      without_partial_double_verification { allow(helper).to receive(:current_user).and_return(user) }
    end

    it 'returns nil without a field value' do
      expect(helper.form_repository_rows_field_value_formatter(nil)).to be_nil
    end

    it 'returns nil when the value has no data' do
      expect(helper.form_repository_rows_field_value_formatter(field_value.tap { |v| v.data = nil })).to be_nil
    end

    it 'joins readable rows with their codes' do
      value = field_value({ 'id' => 1, 'name' => 'First', 'repository_id' => repository.id },
                          { 'id' => 2, 'name' => 'Second', 'repository_id' => repository.id })

      expect(helper.form_repository_rows_field_value_formatter(value))
        .to eq "First (#{RepositoryRow::ID_PREFIX}1) | Second (#{RepositoryRow::ID_PREFIX}2)"
    end

    it 'shows the name when the repository no longer exists' do
      value = field_value({ 'id' => 3, 'name' => 'Gone', 'repository_id' => -1 })

      expect(helper.form_repository_rows_field_value_formatter(value)).to eq "Gone (#{RepositoryRow::ID_PREFIX}3)"
    end

    it 'hides the name of rows from repositories the user cannot read' do
      value = field_value({ 'id' => 4, 'name' => 'Secret', 'repository_id' => other_repository.id })

      expect(helper.form_repository_rows_field_value_formatter(value)).to eq(
        I18n.t('my_modules.assigned_items.repository.private_repository_row_name',
               repository_row_code: "#{RepositoryRow::ID_PREFIX}4")
      )
    end

    it 'checks access for the given user instead of the current one' do
      outsider = create :user
      value = field_value({ 'id' => 5, 'name' => 'Row', 'repository_id' => repository.id })

      expect(helper.form_repository_rows_field_value_formatter(value, outsider))
        .to eq I18n.t('my_modules.assigned_items.repository.private_repository_row_name',
                      repository_row_code: "#{RepositoryRow::ID_PREFIX}5")
    end
  end
end
