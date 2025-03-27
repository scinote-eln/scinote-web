# frozen_string_literal: true

require 'rails_helper'

describe FormRepositoryRowsFieldValue, type: :model do
  let!(:repository) { create :repository }
  let!(:repository_row_1) { create :repository_row, repository: repository }
  let!(:repository_row_2) { create :repository_row, repository: repository }
  let!(:repository_row_3) { create :repository_row, repository: repository }

  let(:form) { create :form }
  let(:form_field) { create :form_field, form: form, data: { type: 'FormRepositoryRowsFieldValue', validations: {} } }
  let(:form_field_value) { (create :form_field_value, type: 'FormRepositoryRowsFieldValue').becomes(FormRepositoryRowsFieldValue) }

  it 'adds new repository row snapshots' do
    form_field_value.update(value: [repository_row_1.id, repository_row_2.id])
    expect(form_field_value.data.pluck('id')).to eq [repository_row_1.id, repository_row_2.id]
    expect(form_field_value.data[0]['snapshot_by_id']).to eq form_field_value.created_by_id
  end

  it 'removes repository row snapshots' do
    form_field_value.update(value: [repository_row_1.id, repository_row_2.id, repository_row_3.id])
    expect(form_field_value.data.pluck('id')).to eq [repository_row_1.id, repository_row_2.id, repository_row_3.id]

    form_field_value.update(value: [repository_row_1.id, repository_row_2.id])
    expect(form_field_value.data.pluck('id')).to eq [repository_row_1.id, repository_row_2.id]
  end

  it 'keeps existing repository row snapshots intact' do
    form_field_value.update(value: [repository_row_1.id, repository_row_2.id])

    existing_snapshot_timestamp = form_field_value.data[0]['snapshot_at']
    existing_snapshot_name = form_field_value.data[0]['name']

    repository_row_1.update(name: "New name!")

    form_field_value.update(value: [repository_row_1.id, repository_row_2.id, repository_row_3.id])
    expect(form_field_value.data.pluck('id')).to eq [repository_row_1.id, repository_row_2.id, repository_row_3.id]

    expect(form_field_value.data[0]['snapshot_at']).to eq existing_snapshot_timestamp
    expect(form_field_value.data[0]['name']).to eq existing_snapshot_name
  end
end
