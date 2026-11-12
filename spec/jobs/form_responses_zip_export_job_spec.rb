# frozen_string_literal: true

require 'rails_helper'
require 'zip'

describe FormResponsesZipExportJob, type: :job do
  let(:user) { create :user }
  let(:team) { create :team, created_by: user }
  let!(:owner_role) { UserRole.find_by(name: I18n.t('user_roles.predefined.owner')) }
  let!(:team_assignment) { create_user_assignment(team, owner_role, user) }
  let(:form) { create :form, team: team, created_by: user, last_modified_by: user, name: 'My form' }
  let!(:text_field) do
    create :form_field, form: form, created_by: user, name: 'Text F', position: 0, data: { type: 'TextField' }
  end
  let!(:number_field) do
    create :form_field, form: form, created_by: user, name: 'Num F', position: 1,
                        data: { type: 'NumberField', unit: 'kg',
                                validations: { response_validation: { enabled: true, min: 1, max: 5 } } }
  end
  let!(:rows_field) do
    create :form_field, form: form, created_by: user, name: 'Rows F', position: 2,
                        data: { type: 'RepositoryRowsField' }
  end
  let(:project) do
    create :project, team: team, created_by: user, name: 'Proj F', default_public_user_role_id: owner_role.id
  end
  let(:experiment) { create :experiment, project: project, created_by: user, name: 'Exp F' }
  let(:my_module) do
    create :my_module, experiment: experiment, created_by: user, name: 'Mod F',
                       my_module_status: MyModuleStatus.first
  end
  let(:step) { create :step, protocol: my_module.protocol, user: user, name: 'Step F' }
  let(:repository) { create :repository, team: team, created_by: user }
  let(:repository_row) do
    create :repository_row, repository: repository, created_by: user, last_modified_by: user, name: 'Row X'
  end
  let(:other_user) { create :user, full_name: 'Other Person' }

  before do
    user.update!(current_team_id: team.id)
    ZipExport.skip_callback(:create, :after, :self_destruct)
  end

  after do
    ZipExport.set_callback(:create, :after, :self_destruct)
  end

  def build_response(attrs = {})
    response = create :form_response, :submitted, form: form, created_by: user, submitted_by: other_user,
                                                  parent: step, step_orderable_element: nil,
                                                  submitted_at: Time.utc(2024, 1, 2, 3, 4, 5), **attrs
    create :step_orderable_element, step: step, orderable: response, position: step.next_element_position
    response
  end

  def exported_sheet
    path = ActiveStorage::Blob.service.public_send(:path_for, ZipExport.last.zip_file.key)
    Zip::File.open(path) do |zip|
      entry = zip.glob('*.xlsx').first
      expect(entry.name).to eq 'My form.xlsx'
      Tempfile.create(['out', '.xlsx']) do |tmp|
        tmp.binmode
        tmp.write(entry.get_input_stream.read)
        tmp.flush
        Roo::Excelx.new(tmp.path).sheet(0).to_a
      end
    end
  end

  def run_job
    described_class.perform_now(user_id: user.id, params: { form_id: form.id })
  end

  it 'exports submitted responses with header, breadcrumbs and field values, and notifies the user' do
    response = build_response
    response.create_value!(user, text_field, 'hello text')
    response.create_value!(user, number_field, 7)
    response.create_value!(user, rows_field, [repository_row.id])
    pending_response = create :form_response, form: form, created_by: user, parent: step,
                                              step_orderable_element: nil
    pending_response.create_value!(user, text_field, 'should not be exported')

    expect { run_job }.to change(ZipExport, :count).by(1).and change(Notification, :count).by(1)

    rows = exported_sheet
    expect(rows.length).to eq 2
    expect(rows[0]).to eq [
      I18n.t('forms.export.columns.form_path'), I18n.t('forms.export.columns.form_timestamp'),
      I18n.t('forms.export.columns.submitted_by'),
      'Text F', I18n.t('forms.export.columns.form_field_timestamp', name: 'Text F'),
      I18n.t('forms.export.columns.form_field_submitted_by', name: 'Text F'),
      'Num F', I18n.t('forms.export.columns.form_field_timestamp', name: 'Num F'),
      I18n.t('forms.export.columns.form_field_submitted_by', name: 'Num F'),
      'Rows F', I18n.t('forms.export.columns.form_field_timestamp', name: 'Rows F'),
      I18n.t('forms.export.columns.form_field_submitted_by', name: 'Rows F')
    ]
    data = rows[1]
    expect(data[0]).to include('Proj F').and include('Exp F').and include('Mod F').and end_with('Step F')
    expect(data[1]).to eq '2024-01-02 03:04:05 UTC'
    expect(data[2]).to eq 'Other Person'
    expect(data[3]).to eq 'hello text'
    expect(data[5]).to eq user.full_name
    expect(data[6]).to eq '7 kg'
    expect(data[9]).to eq "Row X (#{RepositoryRow::ID_PREFIX}#{repository_row.id})"
    expect(ZipExport.last.user).to eq user
  end

  it 'marks values out of range with a warning background and not-applicable values with a label' do
    response = build_response
    response.create_value!(user, number_field, 9)
    response.create_value!(user, text_field, nil, not_applicable: true)

    run_job

    rows = exported_sheet
    expect(rows[1][3]).to eq I18n.t('forms.export.values.not_applicable')
    expect(rows[1][6]).to eq '9 kg'

    path = ActiveStorage::Blob.service.public_send(:path_for, ZipExport.last.zip_file.key)
    xml = Zip::File.open(path) do |zip|
      Tempfile.create(['out', '.xlsx']) do |tmp|
        tmp.binmode
        tmp.write(zip.glob('*.xlsx').first.get_input_stream.read)
        tmp.flush
        Zip::File.open(tmp.path) { |x| x.read('xl/styles.xml') }
      end
    end
    expect(xml).to include('FFFFBF00')
  end

  it 'leaves value cells empty for fields without a value and prefixes archived responses' do
    response = build_response
    response.create_value!(user, text_field, 'only text')
    response.update_columns(archived: true)

    run_job

    row = exported_sheet[1]
    expect(row[0]).to start_with(I18n.t('forms.export.archived'))
    expect(row[3]).to eq 'only text'
    expect(row[6..11].compact).to eq []
  end

  it 'exports an empty path for responses not attached to a step' do
    protocol_step = create :step, user: user, protocol: create(:protocol, :in_repository_draft, team: team, added_by: user)
    response = create :form_response, :submitted, form: form, created_by: user, submitted_by: user,
                                                  parent: protocol_step, step_orderable_element: nil
    expect(response.step.my_module).to be_nil

    run_job

    expect(exported_sheet[1][0]).to be_nil
  end

  describe 'failure' do
    it 'notifies the user with the form specific title and re-raises' do
      allow_any_instance_of(described_class).to receive(:to_xlsx).and_raise(StandardError, 'boom')

      job = described_class.new(user_id: user.id, params: { form_id: form.id })
      job.enqueued_at = Time.current

      expect { job.perform_now }.to raise_error(StandardError, 'boom')

      notification = Notification.last
      expect(notification.to_notification.title).to eq I18n.t('activejob.failure_notifiable_job.item_notification_title',
                                              item: I18n.t('activejob.failure_notifiable_job.items.form'))
    end
  end
end
