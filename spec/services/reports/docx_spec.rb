# frozen_string_literal: true

require 'rails_helper'

describe Reports::Docx do
  include_context 'docx_report'

  describe '#draw' do
    let(:subject_renderer) do
      user.update!(current_team_id: team.id)
      described_class.new(report, caracal_document, user: user, scinote_url: 'http://localhost:3000/')
    end

    before do
      create :report_element, report: report, type_of: :project_header, project: project, position: 0
      experiment_element = create :report_element, report: report, type_of: :experiment, experiment: experiment,
                                                   position: 1
      create :report_element, report: report, type_of: :my_module, my_module: my_module,
                              parent: experiment_element, position: 2
      add_step(name: 'Only step', position: 0)
    end

    it 'draws the generation line, a rule and the whole report tree in order' do
      subject_renderer.draw
      expect(all_text).to include(report.code)
      expect(all_text).to include(Scinote::Application::VERSION)
      expect(heading_texts(1)).to eq([I18n.t('projects.reports.elements.project_header.title', project: 'Docx project')])
      expect(heading_texts(2)).to eq(['Docx experiment'])
      expect(heading_texts(3)).to eq(['Docx task'])
      expect(heading_texts(4).join).to include('Only step')
      expect(document_xml.index('Docx project')).to be < document_xml.index('Docx experiment')
      expect(document_xml.index('Docx experiment')).to be < document_xml.index('Docx task')
      expect(document_node.xpath('//drawing').size).to eq(1)
    end

    context 'without report info metadata' do
      let(:report_settings) { { report_info_metadata: false } }

      it 'draws the short generation line' do
        subject_renderer.draw
        expect(all_text).to include(I18n.t('projects.reports.new.generate_PDF.generated_on', timestamp: '').strip)
        expect(all_text).not_to include(report.code)
        expect(all_text).not_to include(Scinote::Application::VERSION)
      end
    end

    it 'returns the document it draws into' do
      expect(subject_renderer.draw).to be(caracal_document)
    end

    it 'extends the renderer with the template configured in the settings' do
      expect(subject_renderer.singleton_class.ancestors.map(&:to_s)).to include('ScinoteTemplateDocx')
    end
  end

  describe '#get_template_value' do
    it 'returns the value stored for the report template field' do
      report.report_template_values.create!(name: 'author', value: 'Dr. Who', view_component: 'text')
      expect(renderer.send(:get_template_value, 'author')).to eq('Dr. Who')
    end

    it 'returns nil for an unknown field' do
      expect(renderer.send(:get_template_value, 'missing')).to be_nil
    end
  end
end
