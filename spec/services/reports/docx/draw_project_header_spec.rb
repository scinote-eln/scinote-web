# frozen_string_literal: true

require 'rails_helper'

describe Reports::Docx::DrawProjectHeader do
  include_context 'docx_report'

  let(:subject_element) { create :report_element, report: report, type_of: :project_header, project: project }

  def draw
    renderer.draw_project_header(subject_element)
  end

  describe '#draw_project_header' do
    it 'draws a heading with the project name linked to the project' do
      draw
      expect(heading_texts(1)).to eq([I18n.t('projects.reports.elements.project_header.title', project: 'Docx project')])
      path = Rails.application.routes.url_helpers.experiments_path(project_id: project)
      expect(link_targets).to include("http://localhost:3000#{path}")
    end

    it 'draws the creation timestamp line with the project code' do
      draw
      expect(all_text).to include(project.code)
    end

    it 'draws the status label' do
      draw
      expect(all_text).to include(I18n.t("projects.reports.elements.project_header.status.#{project.status}"))
    end

    it 'draws start date, due date and supervisor when set' do
      project.update!(start_date: Time.zone.local(2024, 1, 2, 10), due_date: Time.zone.local(2024, 2, 3, 10),
                      supervised_by: user)
      draw
      expect(all_text).to include(I18n.l(project.start_date, format: :full))
      expect(all_text).to include(I18n.l(project.due_date, format: :full))
      expect(all_text).to include(I18n.t('projects.reports.elements.project_header.supervised_by', user: user.name))
    end

    it 'draws the project description through the html converter' do
      project.update!(description: '<p>Project <b>summary</b> text</p>')
      draw
      expect(all_text).to include('Project')
      expect(all_text).to include('summary')
    end

    context 'when timestamps are excluded' do
      let(:report_settings) { { exclude_timestamps: true } }

      it 'does not draw the creation line' do
        draw
        expect(all_text).not_to include(project.code)
      end
    end

    context 'when task metadata is excluded' do
      let(:report_settings) { { exclude_task_metadata: true } }

      it 'does not draw the status label' do
        project.update!(start_date: Time.zone.local(2024, 1, 2, 10))
        draw
        expect(all_text).not_to include(I18n.t('projects.reports.elements.project_header.status_label'))
        expect(all_text).not_to include(I18n.l(project.start_date, format: :full))
      end
    end

    it 'draws nothing when the user cannot read the project' do
      user.update!(current_team_id: team.id)
      outsider = create :user
      outsider_renderer = Reports::Docx.new(report, caracal_document, user: outsider,
                                                                       scinote_url: 'http://localhost:3000/')
      outsider_renderer.send(:initial_document_load)
      outsider_renderer.draw_project_header(subject_element)
      expect(heading_texts(1)).to be_empty
    end
  end
end
