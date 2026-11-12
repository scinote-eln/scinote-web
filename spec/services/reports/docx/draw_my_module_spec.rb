# frozen_string_literal: true

require 'rails_helper'

describe Reports::Docx::DrawMyModule do
  include_context 'docx_report'

  let(:my_module_element) { create :report_element, report: report, type_of: :my_module, my_module: my_module }

  def draw(**options)
    renderer.draw_my_module(my_module_element, **options)
  end

  describe '#draw_my_module' do
    it 'draws a heading with the task name linked to the task' do
      draw
      expect(heading_texts(3)).to eq(['Docx task'])
      expect(link_targets).to include(
        "http://localhost:3000#{Rails.application.routes.url_helpers.protocols_my_module_path(my_module)}"
      )
    end

    it 'draws the creation line with the task code' do
      draw
      expect(all_text).to include(I18n.t('projects.reports.elements.module.user_time', code: my_module.code,
                                         timestamp: I18n.l(my_module.created_at, format: :full)))
    end

    it 'draws the status of the task' do
      draw
      expect(all_text).to include("[#{my_module.my_module_status.name}]")
    end

    it 'draws start date, due date and tags' do
      tag = create :tag, team: team, name: 'blue-tag', color: '#0000ff'
      create :tagging, taggable: my_module, tag: tag
      my_module.update_columns(started_on: Time.zone.local(2024, 1, 5, 8), due_date: Time.zone.local(2024, 1, 9, 8))
      draw
      expect(all_text).to include(I18n.l(my_module.started_on, format: :full))
      expect(all_text).to include(I18n.l(my_module.due_date, format: :full))
      expect(all_text).to include('[blue-tag]')
      expect(document_xml).to include('w:val="0000ff"')
    end

    it 'draws the completed state and date' do
      my_module.update_columns(state: MyModule.states[:completed], completed_on: Time.zone.local(2024, 2, 2, 8))
      draw
      expect(all_text).to include(I18n.t('my_modules.states.completed'))
      expect(all_text).to include(I18n.l(my_module.completed_on, format: :full))
    end

    it 'draws the task description' do
      my_module.update!(description: '<p>Task description words</p>')
      draw
      expect(all_text).to include('Task description words')
    end

    it 'marks an archived task' do
      my_module.update_columns(archived: true, archived_on: Time.zone.now)
      draw
      expect(all_text).to include(I18n.t('search.index.archived'))
    end

    it 'draws protocol heading, every filtered step and the results heading' do
      step_one = add_step(name: 'First step', position: 0)
      add_step(name: 'Second step', position: 1)
      add_step(name: 'Skipped step', position: 2, completed: false, skipped_at: Time.zone.now)
      create :result, my_module: my_module, name: 'Result one', user: user
      draw
      expect(heading_texts(4)).to include(
        "#{I18n.t('projects.reports.elements.step.step_pos', pos: step_one.position_plus_one)} First step"
      )
      expect(heading_texts(4).grep(/Second step|Skipped step/).size).to eq(2)
      expect(heading_texts(4)).to include(I18n.t('Results'))
    end

    it 'skips results when without_results is set' do
      create :result, my_module: my_module, name: 'Result one', user: user
      draw(without_results: true)
      expect(heading_texts(4)).not_to include(I18n.t('Results'))
    end

    context 'when uncompleted steps are switched off' do
      let(:report_settings) { { task: { protocol: { uncompleted_steps: false } } } }

      it 'excludes steps that do not pass the completed/uncompleted/skipped filter' do
        add_step(name: 'Done step', completed: true)
        add_step(name: 'Open step', completed: false)
        draw
        expect(heading_texts(4).join).to include('Done step')
        expect(heading_texts(4).join).not_to include('Open step')
      end
    end

    it 'draws activities of the task when the setting is on' do
      Activities::CreateActivityService.call(activity_type: :create_module, owner: user, subject: my_module,
                                             team: team, project: project,
                                             message_items: { my_module: my_module.id })
      draw
      expect(heading_texts(4)).to include(
        I18n.t('projects.reports.elements.module_activity.name', my_module: my_module.name)
      )
    end

    context 'when activities are disabled' do
      let(:report_settings) { { task: { activities: false } } }

      it 'does not draw the activity heading' do
        Activities::CreateActivityService.call(activity_type: :create_module, owner: user, subject: my_module,
                                               team: team, project: project,
                                               message_items: { my_module: my_module.id })
        draw
        expect(heading_texts(4)).not_to include(
          I18n.t('projects.reports.elements.module_activity.name', my_module: my_module.name)
        )
      end
    end

    context 'when timestamps and metadata are excluded' do
      let(:report_settings) { { exclude_timestamps: true, exclude_task_metadata: true } }

      it 'does not draw the creation line or the status' do
        draw
        expect(all_text).not_to include(my_module.code)
        expect(all_text).not_to include(I18n.t('projects.reports.elements.module.status'))
      end
    end

    it 'draws nothing for a user that cannot read the task' do
      other = Reports::Docx.new(report, caracal_document, user: create(:user), scinote_url: 'http://localhost:3000/')
      other.send(:initial_document_load)
      other.draw_my_module(my_module_element)
      expect(heading_texts(3)).to be_empty
    end

    context 'with repository children' do
      let(:repository) { create :repository, team: team, created_by: user, name: 'Samples inventory' }
      let!(:row) do
        create(:repository_row, repository: repository, created_by: user, name: 'Sample row').tap do |r|
          create :mm_repository_row, repository_row: r, my_module: my_module, assigned_by: user
        end
      end

      before do
        create :report_element, report: report, type_of: :my_module_repository, my_module: my_module,
                                repository: repository, parent: my_module_element, position: 5
      end

      it 'draws the repository table' do
        draw
        expect(all_text).to include(
          I18n.t('projects.reports.elements.module_repository.name', repository: 'Samples inventory',
                                                                      my_module: my_module.name)
        )
        expect(table_rows.flatten.map(&:strip)).to include('Sample row')
      end

      it 'skips repositories when without_repositories is set' do
        draw(without_repositories: true)
        expect(all_text).not_to include('Samples inventory')
      end
    end
  end
end
