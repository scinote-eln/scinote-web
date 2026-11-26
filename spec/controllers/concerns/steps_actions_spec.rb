# frozen_string_literal: true

require 'rails_helper'

# StepsActions is exercised through StepsController, which includes it.
describe StepsController, type: :controller do
  login_user

  include_context 'reference_project_structure', { step: true }

  let(:mentioned_user) { create :user, full_name: 'Mentioned Person' }
  let(:mention) { "[@#{mentioned_user.full_name}~#{mentioned_user.id.base62_encode}]" }
  let(:task_protocol) { my_module.protocol }
  let(:repo_protocol) { create :protocol, :in_repository_draft, team: team, added_by: user }

  before do
    # current_user needs a processed request; build one for the bare controller instance
    allow(controller).to receive(:current_user).and_return(user)
    controller.instance_variable_set(:@protocol, task_protocol)
    allow(GeneralNotification).to receive(:send_notifications)
  end

  def notified_subjects
    subjects = []
    expect(GeneralNotification).to have_received(:send_notifications).at_least(:once) do |params|
      subjects << [params[:subject_class], params[:subject_id], params[:user_id]]
    end
    subjects
  end

  describe '#annotation_message' do
    it 'links project, experiment and task for task protocols' do
      message = controller.annotation_message(step)

      expect(message).to include(project.name, experiment.name, my_module.name, step.name)
      expect(message).to include("/projects/#{project.id}")
    end

    it 'links the template for repository protocols' do
      controller.instance_variable_set(:@protocol, repo_protocol)
      repo_step = create :step, protocol: repo_protocol

      message = controller.annotation_message(repo_step)

      expect(message).to include(repo_protocol.name)
      expect(message).to include("/protocols/#{repo_protocol.id}/edit")
    end
  end

  describe '#step_description_annotation' do
    it 'notifies newly mentioned users' do
      step.update_column(:description, "Hi #{mention}")

      controller.step_description_annotation(step)

      expect(notified_subjects).to eq [['Step', step.id, mentioned_user.id]]
    end

    it 'does not notify users already mentioned in the old text' do
      step.update_column(:description, "Hi #{mention}")

      controller.step_description_annotation(step, "Earlier #{mention}")

      expect(GeneralNotification).not_to have_received(:send_notifications)
    end

    it 'does nothing for a blank description' do
      controller.step_description_annotation(step)

      expect(GeneralNotification).not_to have_received(:send_notifications)
    end
  end

  describe '#step_text_annotation' do
    it 'notifies users mentioned in the step text' do
      step_text = create :step_text, step: step, text: "<p>#{mention}</p>"

      controller.step_text_annotation(step, step_text)

      expect(notified_subjects).to eq [['StepText', step_text.id, mentioned_user.id]]
    end
  end

  describe '#table_content_annotation' do
    let(:table) { create :table, contents: { data: [[mention]] }.to_json, team: team }

    it 'uses the table title for regular tables' do
      expect(controller).to receive(:smart_annotation_notification)
        .with(hash_including(subject: table, title: include(step.name))).and_call_original

      controller.table_content_annotation(step, table)

      expect(notified_subjects).to eq [['Table', table.id, mentioned_user.id]]
    end

    it 'uses the well plate title for plate templates' do
      table.update!(metadata: { 'plateTemplate' => true })
      allow(controller).to receive(:t).and_call_original
      expect(controller).to receive(:t)
        .with('notifications.step_well_plate_title', any_args).and_call_original

      controller.table_content_annotation(step, table)

      expect(notified_subjects).to eq [['Table', table.id, mentioned_user.id]]
    end
  end

  describe '#create_annotation_notifications' do
    it 'notifies for description, checklist names and checklist items' do
      step.update_column(:description, mention)
      checklist = create :checklist, step: step, name: "List #{mention}"
      item = create :checklist_item, checklist: checklist, text: "Item #{mention}"

      controller.create_annotation_notifications(step)

      expect(notified_subjects).to contain_exactly(
        ['Step', step.id, mentioned_user.id],
        ['Checklist', checklist.id, mentioned_user.id],
        ['Checklist', item.checklist.id, mentioned_user.id]
      )
    end
  end

  describe '#update_annotation_notifications' do
    let(:checklist) { create :checklist, step: step, name: "List #{mention}" }
    let(:item) { create :checklist_item, checklist: checklist, text: "Item #{mention}" }
    let(:new_item_struct) { Struct.new(:id, :text, :checklist) }
    let(:new_checklist_struct) { Struct.new(:id, :name, :items) }

    it 'notifies only for changes compared to the previous checklist state' do
      old_item = StepsActions::PreviousChecklistItem.new(item.id, 'old text')
      old_checklist = StepsActions::PreviousChecklist.new(checklist.id, "List #{mention}")
      old_checklist.add_checklist(old_item)
      new_checklist = new_checklist_struct.new(checklist.id, checklist.name,
                                               [new_item_struct.new(item.id, item.text, checklist)])

      controller.update_annotation_notifications(step, nil, [new_checklist], [old_checklist])

      # checklist name was already mentioning the user, so only the item mention is new
      expect(notified_subjects).to eq [['Checklist', checklist.id, mentioned_user.id]]
      expect(GeneralNotification).to have_received(:send_notifications).once
    end

    it 'treats a checklist with id 0 as new and notifies for name and items' do
      new_checklist = new_checklist_struct.new(0, "Fresh #{mention}",
                                               [new_item_struct.new(nil, "New #{mention}", checklist)])
      allow(controller).to receive(:checklist_name_annotation).and_call_original
      allow(controller).to receive(:checklist_item_annotation).and_call_original

      controller.update_annotation_notifications(step, nil, [new_checklist], [])

      expect(controller).to have_received(:checklist_name_annotation).with(step, new_checklist)
      expect(controller).to have_received(:checklist_item_annotation).with(step, new_checklist.items.first)
    end

    it 'skips checklists that were not present before' do
      new_checklist = new_checklist_struct.new(checklist.id + 1000, "Other #{mention}", [])

      controller.update_annotation_notifications(step, nil, [new_checklist], [])

      expect(GeneralNotification).not_to have_received(:send_notifications)
    end

    it 'uses an empty old text for items that did not exist before' do
      old_checklist = StepsActions::PreviousChecklist.new(checklist.id, checklist.name)
      new_checklist = new_checklist_struct.new(checklist.id, checklist.name,
                                               [new_item_struct.new(item.id, item.text, checklist)])
      allow(controller).to receive(:checklist_item_annotation).and_call_original

      controller.update_annotation_notifications(step, nil, [new_checklist], [old_checklist])

      expect(controller).to have_received(:checklist_item_annotation).with(step, new_checklist.items.first, '')
    end
  end

  describe 'PreviousChecklist' do
    it 'defaults items to an empty list and collects added items' do
      checklist = StepsActions::PreviousChecklist.new(1, 'name')
      checklist.add_checklist(StepsActions::PreviousChecklistItem.new(2, 'text'))

      expect(checklist.items.map(&:id)).to eq [2]
      expect(checklist.items.first.text).to eq 'text'
    end
  end
end
