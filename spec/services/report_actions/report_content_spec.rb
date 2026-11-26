# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ReportActions::ReportContent do
  let(:user) { create :user }
  let(:team) { create :team, created_by: user }
  let(:project) { create :project, team: team, created_by: user }
  let(:experiment) { create :experiment, project: project, created_by: user }
  let!(:my_module_a) { create :my_module, experiment: experiment, created_by: user, name: 'Task A' }
  let!(:my_module_b) { create :my_module, experiment: experiment, created_by: user, name: 'Task B' }
  let(:repository) { create :repository, team: team, created_by: user }
  let(:repository_row) { create :repository_row, repository: repository, created_by: user }
  let(:report) do
    Report.new(name: 'Generated', project: project, user: user, team: team, last_modified_by: user,
               skip_user_assignments: true).tap { |r| r.settings[:task][:repositories] = [repository.id] }
  end
  let(:content) { { 'experiments' => [{ id: experiment.id, my_module_ids: [my_module_b.id, my_module_a.id] }] } }
  let(:template_values) { {} }

  before do
    MyModuleStatusFlow.ensure_default
    user.update!(current_team_id: team.id)
  end

  def service
    described_class.new(report, content, template_values, user)
  end

  def element_tree
    report.report_elements.order(:position).map { |e| [e.type_of, e.position, e.parent&.type_of] }
  end

  describe '#save_with_content' do
    it 'saves the report and builds project header, experiment and task elements in order' do
      service.save_with_content

      expect(report).to be_persisted
      expect(element_tree).to eq [
        ['project_header', 0, nil],
        ['experiment', 1, nil],
        ['my_module', 2, 'experiment'],
        ['my_module', 3, 'experiment']
      ]
      expect(report.report_elements.find_by(type_of: :project_header).project_id).to eq project.id
      expect(report.report_elements.find_by(type_of: :experiment).experiment_id).to eq experiment.id
    end

    it 'orders tasks the way the content lists them' do
      service.save_with_content
      ids = report.report_elements.where(type_of: :my_module).order(:position).pluck(:my_module_id)
      expect(ids).to eq [my_module_b.id, my_module_a.id]
    end

    it 'replaces previously generated elements' do
      service.save_with_content
      old_ids = report.report_elements.pluck(:id)
      described_class.new(report, content, {}, user).save_with_content
      expect(report.report_elements.reload.pluck(:id) & old_ids).to be_empty
      expect(report.report_elements.count).to eq 4
    end

    it 'skips archived tasks and tasks that were not requested' do
      my_module_a.update!(archived: true, archived_on: Time.current)
      content['experiments'].first[:my_module_ids] = [my_module_a.id, my_module_b.id]
      service.save_with_content
      expect(report.report_elements.where(type_of: :my_module).pluck(:my_module_id)).to eq [my_module_b.id]
    end

    it 'skips experiments that do not exist' do
      content['experiments'] << { id: -1, my_module_ids: [my_module_a.id] }
      service.save_with_content
      expect(report.report_elements.where(type_of: :experiment).count).to eq 1
    end

    context 'when the user cannot read the experiment' do
      let(:stranger) { create(:user).tap { |u| u.update!(current_team_id: team.id) } }

      it 'does not add the experiment or its tasks' do
        described_class.new(report, content, {}, stranger).save_with_content
        expect(element_tree).to eq [['project_header', 0, nil]]
      end
    end

    context 'with repositories assigned to a task' do
      let(:other_repository) { create :repository, team: team, created_by: user, name: 'Not selected' }

      before do
        create :mm_repository_row, my_module: my_module_a, repository_row: repository_row, assigned_by: user
        create :mm_repository_row, my_module: my_module_a,
                                   repository_row: create(:repository_row, repository: other_repository, created_by: user),
                                   assigned_by: user
      end

      it 'adds repository elements only for the repositories selected in the report settings' do
        service.save_with_content
        elements = report.report_elements.where(type_of: :my_module_repository)
        expect(elements.map { |e| [e.my_module_id, e.repository_id] }).to eq [[my_module_a.id, repository.id]]
        expect(elements.first.parent.my_module_id).to eq my_module_a.id
      end
    end

    describe 'template values' do
      let(:template_values) do
        { 'title' => { 'view_component' => 'TextInputComponent', 'value' => 'Hello' },
          'when' => { 'view_component' => 'DateInputComponent', 'value' => '03/05/2024' } }
      end

      it 'stores the values with their field names and converts dates to ISO 8601' do
        service.save_with_content
        values = report.report_template_values.to_h { |v| [v.name, [v.view_component, v.value]] }
        expect(values).to eq('title' => ['TextInputComponent', 'Hello'],
                             'when' => ['DateInputComponent', '2024-03-05'])
      end

      it 'replaces earlier template values' do
        service.save_with_content
        described_class.new(report, content, { 'title' => { 'view_component' => 'TextInputComponent', 'value' => 'New' } }, user)
                       .save_with_content
        expect(report.report_template_values.reload.map { |v| [v.name, v.value] }).to eq [%w(title New)]
      end

      it 'rolls everything back on a malformed date' do
        template_values['when']['value'] = 'not a date'
        expect { service.save_with_content }.not_to change(Report, :count)
        expect(ReportElement.count).to eq 0
      end
    end

    describe 'content generation failure' do
      it 'adds a content error and rolls the report back' do
        allow(Rails.logger).to receive(:error)
        content['experiments'] = nil

        expect { service.save_with_content }.not_to change(Report, :count)
        expect(report.errors[:content_error]).to eq [I18n.t('projects.reports.index.generation.content_generation_error')]
        expect(ReportElement.count).to eq 0
      end
    end

    it 'rolls back when the report is invalid' do
      report.name = ''
      allow(Rails.logger).to receive(:error)
      expect { service.save_with_content }.not_to change(Report, :count)
    end
  end
end
