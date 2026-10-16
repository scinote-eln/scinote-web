# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::ReportsController', type: :request do
  let(:user) { create :user }
  let(:other_user) { create :user }
  let(:team) { create :team, created_by: user }
  let(:other_team) { create :team, created_by: other_user }
  let(:project) { create :project, team: team, created_by: user }
  let(:headers) { { 'Authorization': "Bearer #{generate_token(user.id)}" } }
  let!(:old_report) do
    create(:report, user: user, project: project, team: team, name: 'Old report')
      .tap { |r| r.update_columns(created_at: Date.new(2020, 1, 10), updated_at: Date.new(2020, 1, 10)) }
  end
  let!(:new_report) { create :report, user: user, project: project, team: team, name: 'New report' }

  def serialize(records, **opts)
    JSON.parse(
      ActiveModelSerializers::SerializableResource
        .new(records, each_serializer: Api::V1::ReportSerializer, hide_project: true, **opts).to_json
    )['data']
  end

  describe 'GET reports, #index' do
    it 'lists the reports of the project with the report serializer' do
      create :report, user: user, project: create(:project, team: team, created_by: user), team: team,
                      name: 'Other project report'
      get api_v1_team_project_reports_path(team_id: team.id, project_id: project.id), headers: headers

      expect(response).to have_http_status(:ok)
      expect(json[:data].map { |r| r[:id].to_i }).to contain_exactly(old_report.id, new_report.id)
      expect(json[:data]).to match_array(serialize(project.reports))
      expect(json[:data].first[:attributes].keys).to include('name', 'description', 'created_at', 'updated_at')
      expect(json[:data].first[:relationships]).to have_key('user')
      expect(json[:data].first[:relationships]).not_to have_key('project')
    end

    it 'filters by creation date' do
      get api_v1_team_project_reports_path(team_id: team.id, project_id: project.id,
                                           filter: { created_at: { from: '2020-01-01', to: '2020-12-31' } }),
          headers: headers

      expect(json[:data].map { |r| r[:id].to_i }).to eq [old_report.id]
    end

    it 'filters by update date' do
      get api_v1_team_project_reports_path(team_id: team.id, project_id: project.id,
                                           filter: { updated_at: { from: '2021-01-01' } }),
          headers: headers

      expect(json[:data].map { |r| r[:id].to_i }).to eq [new_report.id]
    end

    it 'paginates the reports' do
      get api_v1_team_project_reports_path(team_id: team.id, project_id: project.id,
                                           page: { number: 2, size: 1 }),
          headers: headers

      expect(response).to have_http_status(:ok)
      expect(json[:data].size).to eq 1
    end

    it 'includes file attributes only for generated files' do
      new_report.pdf_file.attach(io: StringIO.new('%PDF-1.4 pdf'), filename: 'r.pdf', content_type: 'application/pdf')
      new_report.docx_file.attach(io: StringIO.new('docx!'), filename: 'r.docx',
                                  content_type: 'application/vnd.openxmlformats-officedocument.wordprocessingml.document')
      get api_v1_team_project_reports_path(team_id: team.id, project_id: project.id), headers: headers

      with_files = json[:data].find { |r| r[:id].to_i == new_report.id }[:attributes]
      without_files = json[:data].find { |r| r[:id].to_i == old_report.id }[:attributes]
      expect(with_files).to include('pdf_file_size' => 12, 'docx_file_size' => 5)
      expect(with_files['pdf_file_url']).to be_present
      expect(with_files['docx_file_url']).to be_present
      expect(without_files.keys).not_to include('pdf_file_size', 'pdf_file_url', 'docx_file_size', 'docx_file_url')
    end

    it 'is forbidden for a project the user cannot read' do
      foreign_project = create :project, team: team, created_by: user
      stranger_headers = { 'Authorization': "Bearer #{generate_token(other_user.id)}" }
      get api_v1_team_project_reports_path(team_id: team.id, project_id: foreign_project.id),
          headers: stranger_headers

      expect(response).to have_http_status(:forbidden).or have_http_status(:not_found)
    end

    it 'returns 404 for a project of another team' do
      foreign_project = create :project, team: other_team, created_by: other_user
      get api_v1_team_project_reports_path(team_id: team.id, project_id: foreign_project.id), headers: headers

      expect(response).to have_http_status(:not_found)
    end

    it 'returns 401 without a token' do
      get api_v1_team_project_reports_path(team_id: team.id, project_id: project.id)

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'GET report, #show' do
    it 'returns the report with its user included' do
      get api_v1_team_project_report_path(team_id: team.id, project_id: project.id, id: new_report.id),
          headers: headers

      expect(response).to have_http_status(:ok)
      expect(json[:data]).to include('id' => new_report.id.to_s, 'type' => 'reports')
      expect(json[:data][:attributes]).to include('name' => 'New report', 'description' => new_report.description)
      expect(json[:data][:relationships][:user][:data]).to include('id' => user.id.to_s)
      expect(json[:included].map { |i| [i[:type], i[:id]] }).to include(['users', user.id.to_s])
    end

    it 'returns 404 for a report of another project' do
      foreign = create :report, user: user, project: create(:project, team: team, created_by: user), team: team
      get api_v1_team_project_report_path(team_id: team.id, project_id: project.id, id: foreign.id), headers: headers

      expect(response).to have_http_status(:not_found)
    end

    it 'returns 404 for an unknown report' do
      get api_v1_team_project_report_path(team_id: team.id, project_id: project.id, id: -1), headers: headers

      expect(response).to have_http_status(:not_found)
    end
  end
end
