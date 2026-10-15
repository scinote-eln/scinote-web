# frozen_string_literal: true

require 'rails_helper'

describe Reports::Docx::DrawStep do
  include_context 'docx_report'

  let(:step) { add_step(name: 'Mix reagents', position: 0) }

  def draw
    renderer.draw_step(step)
  end

  describe '#draw_step' do
    it 'draws the numbered step heading' do
      draw
      expect(heading_texts(4)).to eq(
        ["#{I18n.t('projects.reports.elements.step.step_pos', pos: step.position_plus_one)} Mix reagents"]
      )
    end

    it 'draws completed state with the completion user and time' do
      draw
      expect(all_text).to include(I18n.t('protocols.steps.completed'))
      expect(all_text).to include(
        I18n.t('projects.reports.elements.step.completed.user_time', user: user.full_name,
                                                                      timestamp: I18n.l(step.completed_on, format: :full))
      )
    end

    it 'draws uncompleted state with the creator and creation time' do
      step.update_columns(completed: false, completed_on: nil)
      draw
      expect(all_text).to include(I18n.t('protocols.steps.uncompleted'))
      expect(all_text).to include(
        I18n.t('projects.reports.elements.step.uncompleted.user_time', user: user.full_name,
                                                                        timestamp: I18n.l(step.created_at, format: :full))
      )
    end

    it 'draws the skipped label for a skipped step' do
      step.update_columns(completed: false, completed_on: nil, skipped_at: Time.zone.now)
      draw
      expect(all_text).to include(I18n.t('protocols.steps.skipped'))
    end

    it 'draws archive metadata for an archived step' do
      archived_on = Time.zone.local(2024, 6, 1, 10)
      step.update_columns(archived: true, archived_on: archived_on, archived_by_id: user.id)
      draw
      expect(all_text).to include(I18n.t('search.index.archived'))
      expect(all_text).to include(
        I18n.t('projects.reports.elements.archived_metadata', datetime: I18n.l(archived_on, format: :full),
                                                              user: user.full_name)
      )
    end

    it 'lists linked results' do
      result = create :result, my_module: my_module, name: 'Linked result', user: user
      create :step_result, step: step, result: result
      draw
      expect(all_text).to include(I18n.t('projects.reports.elements.step.linked_results'))
      expect(all_text).to include('Linked result')
    end

    context 'when timestamps are excluded' do
      let(:report_settings) { { exclude_timestamps: true } }

      it 'skips the metadata line' do
        draw
        expect(all_text).not_to include(I18n.t('protocols.steps.completed'))
      end
    end

    context 'with step elements' do
      before do
        text = create :step_text, step: step, name: 'Text element', text: '<p>Body of the text</p>'
        add_step_element(step, text, 0)
        table = create :table, name: 'Step data', contents: { data: [%w(a b), %w(c d)] }.to_json
        add_step_element(step, create(:step_table, step: step, table: table), 1)
        checklist = create :checklist, step: step, name: 'To do'
        create :checklist_item, checklist: checklist, text: 'first item', checked: true, position: 0
        add_step_element(step, checklist, 2)
      end

      it 'draws text, table and checklist elements in order' do
        draw
        texts = paragraph_texts
        text_index = texts.index { |t| t.include?('Body of the text') }
        table_index = texts.index { |t| t.include?('Step data') }
        checklist_index = texts.index { |t| t.include?('To do') }
        expect(text_index).to be < table_index
        expect(table_index).to be < checklist_index
        expect(table_rows).to include(['', 'A', 'B'], ['1', 'a', 'b'])
        expect(all_text).to include('first item')
      end

      context 'when text, table and checklist settings are off' do
        let(:report_settings) do
          { task: { protocol: { step_texts: false, step_tables: false, step_checklists: false } } }
        end

        it 'draws none of the elements' do
          draw
          expect(all_text).not_to include('Body of the text')
          expect(all_text).not_to include('Step data')
          expect(all_text).not_to include('To do')
        end
      end
    end

    context 'with a well plate table' do
      let(:table) do
        create :table, name: 'Plate', contents: { data: [%w(a b), %w(c d)] }.to_json,
                       metadata: { plateTemplate: 'plate_96' }
      end

      before { add_step_element(step, create(:step_table, step: step, table: table), 0) }

      it 'draws the plate with the well plate caption' do
        draw
        expect(all_text).to include(I18n.t('projects.reports.elements.step_well_plates_table.table_name', name: 'Plate'))
      end

      context 'when well plates are switched off' do
        let(:report_settings) { { task: { protocol: { step_well_plates: false } } } }

        it 'does not draw it' do
          draw
          expect(all_text).not_to include('Plate')
        end
      end
    end

    context 'with a normal table when tables are off but metadata is present' do
      let(:report_settings) { { task: { protocol: { step_tables: false } } } }

      it 'does not draw a plain table even with empty metadata' do
        table = create :table, name: 'Plain', metadata: { other: 1 }
        add_step_element(step, create(:step_table, step: step, table: table), 0)
        draw
        expect(all_text).not_to include('Plain')
      end
    end

    context 'with archived elements' do
      let(:report_settings) { { task: { protocol: { archived_steps: true } } } }

      it 'draws archived elements as well' do
        text = create :step_text, step: step, name: 'Old text', text: '<p>gone text</p>'
        text.update!(archived: true, archived_on: Time.zone.now, archived_by: user)
        draw
        expect(all_text).to include('gone text')
      end
    end

    it 'draws step files and comments' do
      asset = create(:step_asset, step: step, team: team).asset
      stub_image_preview(asset)
      create :step_comment, step: step, user: user, message: 'Looks fine'
      draw
      expect(all_text).to include(asset.file_name)
      expect(all_text).to include('Looks fine')
      expect(document_node.xpath('//drawing').size).to eq(1)
    end

    context 'when files and comments are off' do
      let(:report_settings) { { task: { protocol: { step_files: false, step_comments: false } } } }

      it 'draws neither' do
        asset = create(:step_asset, step: step, team: team).asset
        create :step_comment, step: step, user: user, message: 'Looks fine'
        draw
        expect(all_text).not_to include(asset.file_name)
        expect(all_text).not_to include('Looks fine')
      end
    end

    it 'draws form responses when step forms are on' do
      form = create :form, team: team, created_by: user, last_modified_by: user, name: 'Form A'
      field = create :form_field, form: form, created_by: user, name: 'Field A', position: 0,
                                  data: { type: 'TextField' }
      response = create :form_response, :submitted, form: form, created_by: user, submitted_by: user,
                                                    parent: step, step_orderable_element: nil
      add_step_element(step, response, 0)
      response.create_value!(user, field, 'answer a')
      draw
      expect(all_text).to include('Field A')
      expect(all_text).to include('answer a')
    end
  end
end
