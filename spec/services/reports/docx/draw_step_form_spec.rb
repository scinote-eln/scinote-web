# frozen_string_literal: true

require 'rails_helper'

describe Reports::Docx::DrawStepForm do
  include_context 'docx_report'

  let(:step) { add_step(name: 'Form step') }
  let(:form) { create :form, team: team, created_by: user, last_modified_by: user, name: 'Quality form' }
  let(:submitter) { create :user, full_name: 'Form Submitter' }
  let(:status) { :submitted }
  let!(:text_field) do
    create :form_field, form: form, created_by: user, name: 'Text F', position: 0, data: { type: 'TextField' }
  end
  let!(:number_field) do
    create :form_field, form: form, created_by: user, name: 'Num F', position: 1,
                        data: { type: 'NumberField', unit: 'kg' }
  end
  let!(:date_field) do
    create :form_field, form: form, created_by: user, name: 'Date F', position: 2,
                        data: { type: 'DatetimeField', time: false }
  end
  let!(:rows_field) do
    create :form_field, form: form, created_by: user, name: 'Rows F', position: 3,
                        data: { type: 'RepositoryRowsField' }
  end
  let!(:empty_field) do
    create :form_field, form: form, created_by: user, name: 'Empty F', position: 4, data: { type: 'TextField' }
  end
  let(:repository) { create :repository, team: team, created_by: user }
  let(:repository_row) { create :repository_row, repository: repository, created_by: user, name: 'Row X' }
  let(:form_response) do
    create :form_response, status, form: form, created_by: user, submitted_by: submitter, parent: step,
                                   step_orderable_element: nil
  end

  before do
    add_step_element(step, form_response, 0)
    form_response.create_value!(submitter, text_field, 'plain answer')
    form_response.create_value!(submitter, number_field, 12)
    form_response.create_value!(submitter, date_field, '2024-03-05')
    form_response.create_value!(submitter, rows_field, [repository_row.id])
  end

  def draw
    renderer.draw_step_forms(form_response)
  end

  it 'draws a table with header, one row per field, answers and submitter' do
    draw
    rows = table_rows
    expect(rows.first).to eq(
      %w(field answer submitted_at submitted_by).map { |k| I18n.t("projects.reports.elements.step_forms.#{k}") }
    )
    by_name = rows.drop(1).to_h { |row| [row[0], row] }
    expect(by_name.keys).to eq(['Text F', 'Num F', 'Date F', 'Rows F', 'Empty F'])
    expect(by_name['Text F'][1]).to eq('plain answer')
    expect(by_name['Text F'][3]).to eq('Form Submitter')
    expect(by_name['Num F'][1]).to eq('12 kg')
    expect(by_name['Date F'][1]).to include('2024')
    expect(by_name['Rows F'][1]).to eq("Row X (#{RepositoryRow::ID_PREFIX}#{repository_row.id})")
    expect(by_name['Empty F'][1..3]).to eq(['', '', ''])
  end

  it 'draws not applicable values with a label' do
    form_response.create_value!(submitter, text_field, nil, not_applicable: true)
    draw
    expect(table_rows.drop(1).first[1]).to eq(I18n.t('forms.export.values.not_applicable'))
  end

  it 'draws the form name with the submission user and time' do
    draw
    expect(all_text).to include(I18n.t('projects.reports.elements.step_forms.table_name', name: 'Quality form'))
    expect(all_text).to include(
      I18n.t('projects.reports.elements.step_forms.user_time', user: 'Form Submitter',
                                                               timestamp: I18n.l(form_response.submitted_at, format: :full))
    )
  end

  it 'draws archive metadata for an archived response' do
    archived_on = Time.zone.local(2024, 5, 5, 5)
    form_response.update_columns(archived: true, archived_on: archived_on, archived_by_id: user.id)
    pending 'bug: draw_step_forms reads form_response.archived_at, but the column is archived_on (NoMethodError)'
    draw
    expect(all_text).to include(I18n.t('search.index.archived'))
    expect(all_text).to include(
      I18n.t('projects.reports.elements.archived_metadata', datetime: I18n.l(archived_on, format: :full),
                                                            user: user.full_name)
    )
  end

  context 'when the response is not submitted' do
    let(:status) { :pending }

    it 'draws the not submitted note' do
      draw
      expect(all_text).to include(I18n.t('projects.reports.elements.step_forms.not_submitted'))
    end
  end

  context 'when timestamps are excluded' do
    let(:report_settings) { { exclude_timestamps: true } }

    it 'does not draw the submission line' do
      draw
      expect(all_text).not_to include(
        I18n.t('projects.reports.elements.step_forms.user_time', user: 'Form Submitter',
                                                                 timestamp: I18n.l(form_response.submitted_at, format: :full))
      )
    end
  end

  context 'when step forms are switched off' do
    let(:report_settings) { { task: { protocol: { step_forms: false } } } }

    it 'draws nothing' do
      draw
      expect(document_node.xpath('//tbl')).to be_empty
    end
  end
end
