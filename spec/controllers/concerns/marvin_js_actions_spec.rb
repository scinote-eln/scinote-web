# frozen_string_literal: true

require 'rails_helper'

describe MarvinJsActions do
  let(:host_class) do
    Class.new do
      include MarvinJsActions

      def t(key, **opts)
        I18n.t(key, **opts)
      end

      public :create_edit_marvinjs_activity, :create_create_marvinjs_activity, :create_delete_marvinjs_activity
    end
  end
  let(:host) { host_class.new }
  let(:user) { create :user }
  let(:team) { create :team, created_by: user }
  let(:project) { create :project, team: team, created_by: user }
  let(:experiment) { create :experiment, project: project, created_by: user }
  let(:my_module) { create :my_module, experiment: experiment, created_by: user }
  let(:step) { create :step, protocol: my_module.protocol, user: user }
  let(:result) { create :result, my_module: my_module, user: user }
  let(:image_path) { Rails.root.join('spec/fixtures/files/test.jpg') }

  before { allow(Activities::CreateActivityService).to receive(:call) }

  def marvin_metadata
    { name: 'Benzene', asset_type: 'marvinjs' }
  end

  def build_asset(parent: nil, metadata: marvin_metadata)
    asset = create :asset, team: team, created_by: user, last_modified_by: user
    asset.file.attach(io: File.open(image_path), filename: 'sketch.jpg', content_type: 'image/jpeg',
                      metadata: metadata)
    StepAsset.create!(step: parent, asset: asset) if parent.is_a?(Step)
    ResultAsset.create!(result: parent, asset: asset) if parent.is_a?(Result)
    asset.reload
  end

  def build_tiny_asset(object, metadata: marvin_metadata)
    asset = TinyMceAsset.create!(team: team, object: object)
    asset.image.attach(io: File.open(image_path), filename: 'sketch.jpg', content_type: 'image/jpeg',
                       metadata: metadata)
    asset
  end

  describe 'file assets on a step in a task' do
    let(:asset) { build_asset(parent: step) }

    it 'logs a create activity with step and task details' do
      host.create_create_marvinjs_activity(asset, user)

      expect(Activities::CreateActivityService).to have_received(:call).with(
        activity_type: :create_chemical_structure_on_step,
        owner: user,
        subject: my_module.protocol,
        team: team,
        project: project,
        message_items: {
          step: step.id,
          step_position: { id: step.id, value_for: 'position_plus_one' },
          'asset_name' => { id: asset.id, value_for: 'file_name' },
          my_module: my_module.id
        }
      )
    end

    it 'logs a delete activity' do
      host.create_delete_marvinjs_activity(asset, user)

      expect(Activities::CreateActivityService).to have_received(:call)
        .with(hash_including(activity_type: :delete_chemical_structure_on_step))
    end

    it 'logs a started-editing activity with the translated action' do
      host.create_edit_marvinjs_activity(asset, user, :start_editing)

      expect(Activities::CreateActivityService).to have_received(:call).with(
        hash_including(activity_type: :edit_chemical_structure_on_step,
                       message_items: hash_including(action: I18n.t('activities.file_editing.started')))
      )
    end

    it 'logs a finished-editing activity with the translated action' do
      host.create_edit_marvinjs_activity(asset, user, :finish_editing)

      expect(Activities::CreateActivityService).to have_received(:call).with(
        hash_including(message_items: hash_including(action: I18n.t('activities.file_editing.finished')))
      )
    end

    it 'logs an edit activity without an action for an unknown editing state' do
      host.create_edit_marvinjs_activity(asset, user, :other)

      expect(Activities::CreateActivityService).to have_received(:call) do |args|
        expect(args[:activity_type]).to eq :edit_chemical_structure_on_step
        expect(args[:message_items]).not_to have_key(:action)
      end
    end

    it 'does nothing for an asset that is not a marvinjs sketch' do
      plain = build_asset(parent: step, metadata: { name: 'x' })
      host.create_create_marvinjs_activity(plain, user)

      expect(Activities::CreateActivityService).not_to have_received(:call)
    end

    it 'does nothing for an asset that is not attached to any object' do
      host.create_create_marvinjs_activity(build_asset, user)

      expect(Activities::CreateActivityService).not_to have_received(:call)
    end
  end

  describe 'file assets on a step in a protocol repository' do
    let(:protocol) { create :protocol, :in_repository_draft, team: team, added_by: user }
    let(:repo_step) { create :step, protocol: protocol, user: user }
    let(:asset) { build_asset(parent: repo_step) }

    it 'logs the repository variant of the activity' do
      host.create_create_marvinjs_activity(asset, user)

      expect(Activities::CreateActivityService).to have_received(:call).with(
        hash_including(activity_type: :create_chemical_structure_on_step_in_repository,
                       subject: protocol,
                       team: team,
                       project: nil,
                       message_items: hash_including(protocol: protocol.id, step: repo_step.id))
      )
    end
  end

  describe 'file assets on a result' do
    let(:asset) { build_asset(parent: result) }

    it 'logs a result activity with the parent task' do
      host.create_create_marvinjs_activity(asset, user)

      expect(Activities::CreateActivityService).to have_received(:call).with(
        activity_type: :create_chemical_structure_on_result,
        owner: user,
        subject: result,
        team: team,
        project: nil,
        message_items: {
          result: result.id,
          'asset_name' => { id: asset.id, value_for: 'file_name' },
          my_module: my_module.id
        }
      )
    end

    it 'adds the action for edits' do
      host.create_edit_marvinjs_activity(asset, user, :start_editing)

      expect(Activities::CreateActivityService).to have_received(:call).with(
        hash_including(activity_type: :edit_chemical_structure_on_result,
                       message_items: hash_including(action: I18n.t('activities.file_editing.started')))
      )
    end
  end

  describe 'tiny mce assets' do
    it 'logs a step activity for an asset in a step text' do
      step_text = create :step_text, step: step
      asset = build_tiny_asset(step_text)
      host.create_create_marvinjs_activity(asset, user)

      expect(Activities::CreateActivityService).to have_received(:call).with(
        hash_including(
          activity_type: :create_chemical_structure_on_step,
          subject: my_module.protocol,
          message_items: hash_including('tiny_mce_asset_name' => { id: asset.id, value_for: 'file_name' },
                                        step: step.id, my_module: my_module.id)
        )
      )
    end

    it 'logs a step activity for an asset attached directly to a step' do
      pending 'bug: marvinjs_step_activity calls step on the object, which is already a Step'

      asset = build_tiny_asset(step)
      host.create_delete_marvinjs_activity(asset, user)

      expect(Activities::CreateActivityService).to have_received(:call)
        .with(hash_including(activity_type: :delete_chemical_structure_on_step))
    end

    it 'logs a result activity for an asset in a result text' do
      result_text = create :result_text, result: result
      asset = build_tiny_asset(result_text)
      host.create_create_marvinjs_activity(asset, user)

      expect(Activities::CreateActivityService).to have_received(:call).with(
        hash_including(
          activity_type: :create_chemical_structure_on_result,
          subject: result,
          message_items: hash_including('tiny_mce_asset_name' => { id: asset.id, value_for: 'file_name' },
                                        result: result.id, my_module: my_module.id)
        )
      )
    end

    it 'logs a task activity for an asset in a task description' do
      asset = build_tiny_asset(my_module)
      host.create_edit_marvinjs_activity(asset, user, :finish_editing)

      expect(Activities::CreateActivityService).to have_received(:call).with(
        activity_type: :edit_chemical_structure_on_task,
        owner: user,
        subject: my_module,
        team: team,
        project: project,
        message_items: {
          my_module: my_module.id,
          tiny_mce_asset_name: { id: asset.id, value_for: 'file_name' },
          action: I18n.t('activities.file_editing.finished')
        }
      )
    end

    it 'logs a task protocol activity for an asset in a protocol of a task' do
      asset = build_tiny_asset(my_module.protocol)
      host.create_create_marvinjs_activity(asset, user)

      expect(Activities::CreateActivityService).to have_received(:call).with(
        hash_including(activity_type: :create_chemical_structure_on_task_protocol,
                       subject: my_module.protocol,
                       project: project,
                       message_items: hash_including(my_module: my_module.id))
      )
    end

    it 'logs a repository protocol activity for an asset in a repository protocol' do
      protocol = create :protocol, :in_repository_draft, team: team, added_by: user
      asset = build_tiny_asset(protocol)
      host.create_create_marvinjs_activity(asset, user)

      expect(Activities::CreateActivityService).to have_received(:call).with(
        hash_including(activity_type: :create_chemical_structure_on_protocol,
                       subject: protocol,
                       team: team,
                       message_items: hash_including(protocol: protocol.id))
      )
    end

    it 'does nothing for an asset without the marvinjs type' do
      asset = build_tiny_asset(my_module, metadata: { name: 'x' })
      host.create_create_marvinjs_activity(asset, user)

      expect(Activities::CreateActivityService).not_to have_received(:call)
    end
  end

  describe 'missing asset' do
    it 'does nothing for a nil asset' do
      host.create_edit_marvinjs_activity(nil, user, :finish_editing)
      host.create_create_marvinjs_activity(nil, user)

      expect(Activities::CreateActivityService).not_to have_received(:call)
    end
  end
end
