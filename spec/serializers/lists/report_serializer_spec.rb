# frozen_string_literal: true

require 'rails_helper'

describe Lists::ReportSerializer do
  include Rails.application.routes.url_helpers

  let(:user) { create :user, full_name: 'Creator Person' }
  let(:team) { create :team, created_by: user }
  let(:project) { create :project, team: team, created_by: user, name: 'Serialized project' }
  let(:modifier) { create :user, full_name: 'Modifier Person' }
  let(:report) do
    create :report, user: user, project: project, team: team, name: 'Serialized report', last_modified_by: modifier
  end
  # the datatable and list services hand over reports selected with these aliases
  let(:record) do
    Report.joins(:project)
          .joins('LEFT OUTER JOIN users AS creators ON reports.user_id = creators.id')
          .joins('LEFT OUTER JOIN users AS modifiers ON reports.last_modified_by_id = modifiers.id')
          .select('reports.*, projects.name AS project_name, creators.full_name AS created_by_name, ' \
                  'modifiers.full_name AS modified_by_name')
          .find(report.id)
  end
  let(:serializer) { described_class.new(record) }
  let(:attributes) { serializer.as_json }

  it 'exposes names taken from the joined columns' do
    expect(attributes).to include(name: 'Serialized report', project_name: 'Serialized project',
                                  created_by_name: 'Creator Person', modified_by_name: 'Modifier Person',
                                  code: report.code)
  end

  it 'formats the dates with the full format' do
    expect(attributes).to include(created_at: I18n.l(report.created_at, format: :full),
                                  updated_at: I18n.l(report.updated_at, format: :full))
  end

  describe '#archived' do
    it 'is false for an active project' do
      expect(serializer.archived).to be false
    end

    it 'is true for an archived project' do
      project.update_column(:archived, true)

      expect(described_class.new(record.reload).archived).to be true
    end
  end

  describe 'file states' do
    it 'reports processing and error states without preview urls when nothing is attached' do
      report.pdf_processing!
      report.docx_error!

      expect(attributes[:pdf_file]).to eq(processing: true, preview_url: nil, error: false)
      expect(attributes[:docx_file]).to eq(processing: false, preview_url: nil, error: true)
    end

    it 'adds preview urls for attached files' do
      report.pdf_file.attach(io: StringIO.new('%PDF'), filename: 'r.pdf', content_type: 'application/pdf')
      report.docx_file.attach(io: StringIO.new('docx'), filename: 'r.docx', content_type: 'application/octet-stream')

      expect(attributes[:pdf_file][:preview_url]).to eq document_preview_report_path(report, report_type: :pdf)
      expect(attributes[:docx_file][:preview_url]).to eq document_preview_report_path(report, report_type: :docx)
    end
  end

  it 'lists the action urls of the report' do
    expect(attributes[:urls]).to eq(
      edit: edit_project_report_path(project.id, report.id),
      status: status_project_report_path(project.id, report.id),
      generate_pdf: generate_pdf_project_report_path(project.id, report.id),
      generate_docx: generate_docx_project_report_path(project.id, report.id),
      save_to_inventory: save_pdf_to_inventory_item_report_path(report)
    )
  end
end
