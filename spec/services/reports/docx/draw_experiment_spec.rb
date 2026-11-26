# frozen_string_literal: true

require 'rails_helper'

describe Reports::Docx::DrawExperiment do
  include_context 'docx_report'

  let(:experiment_element) { create :report_element, report: report, type_of: :experiment, experiment: experiment }

  def draw
    renderer.draw_experiment(experiment_element)
  end

  describe '#draw_experiment' do
    it 'draws a heading with the experiment name linked to the experiment' do
      draw
      expect(heading_texts(2)).to eq(['Docx experiment'])
      expect(link_targets).to include(
        "http://localhost:3000#{Rails.application.routes.url_helpers.my_modules_experiment_path(experiment)}"
      )
    end

    it 'draws the creation line with the experiment code' do
      draw
      expect(all_text).to include(I18n.t('projects.reports.elements.experiment.user_time',
                                         code: experiment.code,
                                         timestamp: I18n.l(experiment.created_at, format: :full)))
    end

    it 'draws the status label' do
      draw
      expect(all_text).to include(I18n.t('projects.reports.elements.experiment.status_label'))
      expect(all_text).to include(I18n.t("projects.reports.elements.experiment.status.#{experiment.status}"))
    end

    it 'draws the experiment description' do
      experiment.update!(description: '<p>Experiment goal text</p>')
      draw
      expect(all_text).to include('Experiment goal text')
    end

    it 'draws start and due dates when present' do
      experiment.update_columns(start_date: Date.new(2024, 3, 4), due_date: Time.zone.local(2024, 5, 6, 9))
      draw
      expect(all_text).to include(I18n.l(experiment.start_date, format: :full))
      expect(all_text).to include(I18n.l(experiment.due_date, format: :full))
    end

    it 'marks an archived experiment' do
      experiment.update_columns(archived: true, archived_on: Time.zone.now)
      draw
      expect(all_text).to include("#{I18n.t('search.index.archived')}")
      expect(all_text).to include(' | ')
    end

    it 'draws its child elements (tasks) after the experiment header' do
      create :report_element, report: report, type_of: :my_module, my_module: my_module,
                              parent: experiment_element, position: 2
      draw
      expect(heading_texts(2)).to eq(['Docx experiment'])
      expect(heading_texts(3)).to eq(['Docx task'])
    end

    context 'when timestamps and metadata are excluded' do
      let(:report_settings) { { exclude_timestamps: true, exclude_task_metadata: true } }

      it 'draws only the heading and the description' do
        draw
        expect(all_text).not_to include(experiment.code)
        expect(all_text).not_to include(I18n.t('projects.reports.elements.experiment.status_label'))
      end
    end

    it 'draws nothing for a user that cannot read the experiment' do
      outsider = create :user
      other = Reports::Docx.new(report, caracal_document, user: outsider, scinote_url: 'http://localhost:3000/')
      other.send(:initial_document_load)
      other.draw_experiment(experiment_element)
      expect(heading_texts(2)).to be_empty
    end
  end
end
