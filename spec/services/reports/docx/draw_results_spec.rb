# frozen_string_literal: true

require 'rails_helper'

# Covers DrawResults and the result element drawers (text, table, asset, comments)
describe Reports::Docx::DrawResults do
  include_context 'docx_report'

  let!(:result) { create :result, my_module: my_module, name: 'Result one', user: user }

  def draw(**options)
    renderer.draw_results(my_module, **options)
  end

  it 'draws nothing when the task has no results' do
    empty_module = create :my_module, experiment: experiment, created_by: user, name: 'No results',
                                      my_module_status: my_module.my_module_status
    renderer.draw_results(empty_module)
    expect(heading_texts(4)).to be_empty
  end

  it 'draws the results heading and the result line with author and time' do
    draw
    expect(heading_texts(4)).to eq([I18n.t('Results')])
    expect(all_text).to include('Result one')
    expect(all_text).to include(
      I18n.t('projects.reports.elements.result.user_time', timestamp: I18n.l(result.created_at, format: :full),
                                                           user: user.full_name)
    )
  end

  it 'draws the task name as a linked heading with with_my_module_name' do
    draw(with_my_module_name: true)
    expect(heading_texts(3)).to eq(['Docx task'])
    expect(link_targets).to include(
      "http://localhost:3000#{Rails.application.routes.url_helpers.protocols_my_module_path(my_module)}"
    )
  end

  it 'draws nothing for a user without read access' do
    other = Reports::Docx.new(report, caracal_document, user: create(:user), scinote_url: 'http://localhost:3000/')
    other.send(:initial_document_load)
    other.draw_results(my_module)
    expect(heading_texts(4)).to be_empty
  end

  it 'uses the unnamed label for a nameless result' do
    result.update_columns(name: nil)
    draw
    expect(all_text).to include(I18n.t('projects.reports.unnamed'))
  end

  it 'lists linked steps' do
    step = add_step(name: 'Source step', position: 0)
    create :step_result, step: step, result: result
    draw
    expect(all_text).to include(I18n.t('projects.reports.elements.result.linked_steps'))
    expect(all_text).to include(step.label)
  end

  it 'draws archive metadata for an archived result' do
    archived_on = Time.zone.local(2024, 10, 10, 10)
    result.update_columns(archived: true, archived_on: archived_on, archived_by_id: user.id)
    draw
    expect(all_text).to include(I18n.t('search.index.archived'))
    expect(all_text).to include(
      I18n.t('projects.reports.elements.archived_metadata', datetime: I18n.l(archived_on, format: :full),
                                                            user: user.full_name)
    )
  end

  context 'when archived results are not wanted' do
    let(:report_settings) { { task: { archived_results: false } } }

    it 'skips archived results' do
      result.update_columns(archived: true, archived_on: Time.zone.now, archived_by_id: user.id)
      draw
      expect(heading_texts(4)).to be_empty
    end
  end

  context 'when timestamps and metadata are excluded' do
    let(:report_settings) { { exclude_timestamps: true, exclude_task_metadata: true } }

    it 'draws only the result name' do
      step = add_step(name: 'Source step', position: 0)
      create :step_result, step: step, result: result
      draw
      expect(all_text).to include('Result one')
      expect(all_text).not_to include(I18n.t('projects.reports.elements.result.linked_steps'))
      expect(all_text).not_to include(user.full_name)
    end
  end

  context 'when no result type is enabled' do
    let(:report_settings) { { task: { file_results: false, table_results: false, text_results: false } } }

    it 'draws nothing' do
      draw
      expect(heading_texts(4)).to be_empty
    end
  end

  describe 'result order' do
    before do
      create :result, my_module: my_module, name: 'A result', user: user, created_at: 3.days.ago
      create :result, my_module: my_module, name: 'Z result', user: user, created_at: 1.day.ago
      result.update_columns(created_at: 2.days.ago)
    end

    def drawn_names
      paragraph_texts.filter_map { |t| t[/\A(A result|Z result|Result one)/] }
    end

    it 'draws the newest first by default' do
      draw
      expect(drawn_names).to eq(['Z result', 'Result one', 'A result'])
    end

    context 'with a to z order' do
      let(:report_settings) { { task: { result_order: 'atoz' } } }

      it 'sorts by name ascending' do
        draw
        expect(drawn_names).to eq(['A result', 'Result one', 'Z result'])
      end
    end

    context 'with a z to a order' do
      let(:report_settings) { { task: { result_order: 'ztoa' } } }

      it 'sorts by name descending' do
        draw
        expect(drawn_names).to eq(['Z result', 'Result one', 'A result'])
      end
    end
  end

  describe 'result texts' do
    let!(:result_text) do
      create(:result_text, result: result, name: 'Observations', text: '<p>Cells grew <i>well</i></p>').tap do |rt|
        add_result_element(result, rt, 0)
      end
    end

    it 'draws name, timestamp and body' do
      draw
      expect(all_text).to include('Observations')
      expect(all_text).to include(
        I18n.t('projects.reports.elements.result_text.user_time',
               timestamp: I18n.l(result_text.created_at, format: :full))
      )
      expect(all_text).to include('Cells grew')
    end

    it 'draws archive metadata for an archived text when archived results are on' do
      archived_on = Time.zone.local(2024, 11, 11, 11)
      result_text.update_columns(archived: true, archived_on: archived_on, archived_by_id: user.id)
      draw
      expect(all_text).to include(
        I18n.t('projects.reports.elements.archived_metadata', datetime: I18n.l(archived_on, format: :full),
                                                              user: user.full_name)
      )
    end

    context 'when timestamps are excluded' do
      let(:report_settings) { { exclude_timestamps: true } }

      it 'keeps only the name' do
        draw
        expect(all_text).not_to include(
          I18n.t('projects.reports.elements.result_text.user_time',
                 timestamp: I18n.l(result_text.created_at, format: :full))
        )
        expect(all_text).to include('Observations')
      end
    end

    context 'when text results are off' do
      let(:report_settings) { { task: { text_results: false } } }

      it 'skips texts' do
        draw
        expect(all_text).not_to include('Cells grew')
      end
    end
  end

  describe 'result tables' do
    let(:table) { create :table, name: 'Result grid', contents: { data: [%w(p q), %w(r s)] }.to_json }

    before do
      add_result_element(result, create(:result_table, result: result, table: table), 0)
    end

    it 'draws the table and its caption' do
      draw
      expect(table_rows).to eq([['', 'A', 'B'], %w(1 p q), %w(2 r s)])
      expect(all_text).to include(I18n.t('projects.reports.elements.result_table.table_name', name: 'Result grid'))
      expect(all_text).to include(
        I18n.t('projects.reports.elements.result_table.user_time', timestamp: I18n.l(table.created_at, format: :full),
                                                                   user: user.full_name)
      )
    end

    it 'draws a well plate result table' do
      table.update!(metadata: { plateTemplate: 'plate_96' })
      draw
      expect(table_rows.first).to eq(['', '1', '2'])
    end

    it 'draws archive metadata for an archived table' do
      archived_on = Time.zone.local(2024, 12, 12, 12)
      table.update_columns(archived: true, archived_on: archived_on, archived_by_id: user.id)
      draw
      expect(all_text).to include(
        I18n.t('projects.reports.elements.archived_metadata', datetime: I18n.l(archived_on, format: :full),
                                                              user: user.full_name)
      )
    end

    context 'when timestamps are excluded' do
      let(:report_settings) { { exclude_timestamps: true } }

      it 'draws only the table name' do
        draw
        expect(all_text).not_to include(
          I18n.t('projects.reports.elements.result_table.user_time',
                 timestamp: I18n.l(table.created_at, format: :full), user: user.full_name)
        )
      end
    end

    context 'when table results are off' do
      let(:report_settings) { { task: { table_results: false } } }

      it 'skips tables' do
        draw
        expect(all_text).not_to include('Result grid')
      end
    end
  end

  describe 'result files' do
    let(:asset) { create(:result_asset, result: result, team: team).asset }

    before { stub_image_preview(asset) }

    it 'draws the image, file name, download link and timestamp' do
      draw
      expect(document_node.xpath('//drawing').size).to eq(1)
      expect(all_text).to include(I18n.t('projects.reports.elements.result_asset.file_name', file: asset.file_name))
      expect(all_text).to include(
        I18n.t('projects.reports.elements.result_asset.user_time', user: user.full_name,
                                                                   timestamp: I18n.l(asset.created_at, format: :full))
      )
      expect(link_targets).to include(Rails.application.routes.url_helpers.asset_download_url(asset))
    end

    it 'draws a preview error line when rendering the image fails' do
      allow(Reports::Utils).to receive(:image_prepare).and_raise(StandardError, 'broken')
      draw
      expect(document_node.xpath('//drawing')).to be_empty
      expect(all_text).to include(I18n.t('projects.reports.index.generation.file_preview_generation_error'))
    end

    it 'draws archive metadata for an archived file' do
      archived_on = Time.zone.local(2024, 1, 2, 3)
      asset.update_columns(archived: true, archived_on: archived_on, archived_by_id: user.id)
      draw
      expect(all_text).to include(
        I18n.t('projects.reports.elements.archived_metadata', datetime: I18n.l(archived_on, format: :full),
                                                              user: user.full_name)
      )
    end

    context 'when timestamps are excluded' do
      let(:report_settings) { { exclude_timestamps: true } }

      it 'omits the timestamp' do
        draw
        expect(all_text).not_to include(
          I18n.t('projects.reports.elements.result_asset.user_time', user: user.full_name,
                                                                     timestamp: I18n.l(asset.created_at, format: :full))
        )
      end
    end

    context 'when file results are off' do
      let(:report_settings) { { task: { file_results: false } } }

      it 'skips files' do
        draw
        expect(all_text).not_to include(asset.file_name)
      end
    end
  end

  describe 'result comments' do
    before do
      create :result_comment, result: result, user: user, message: 'first <b>note</b>',
                              created_at: Time.zone.local(2024, 1, 1, 9)
      create :result_comment, result: result, user: user, message: 'second note',
                              created_at: Time.zone.local(2024, 1, 2, 9)
    end

    it 'draws the heading and comments with author and timestamp' do
      draw
      expect(all_text).to include(I18n.t('projects.reports.elements.result_comments.name', result: 'Result one'))
      expect(all_text).to include('second note')
      expect(all_text).to include('first')
      expect(all_text).to include(
        I18n.t('projects.reports.elements.result_comments.comment_prefix', user: user.full_name,
                                                                           date: I18n.l(Time.zone.local(2024, 1, 2, 9), format: :full_date),
                                                                           time: I18n.l(Time.zone.local(2024, 1, 2, 9), format: :time))
      )
    end

    it 'draws the newest comment first' do
      pending 'bug: comments.find_each ignores order(created_at: :desc) and draws them by id'
      draw
      expect(all_text.index('second note')).to be < all_text.index('first')
    end

    context 'when result comments are off' do
      let(:report_settings) { { task: { result_comments: false } } }

      it 'skips comments' do
        draw
        expect(all_text).not_to include('second note')
      end
    end
  end
end
