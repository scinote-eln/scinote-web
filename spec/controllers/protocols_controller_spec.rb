# frozen_string_literal: true

require 'rails_helper'

describe ProtocolsController, type: :controller do
  login_user

  include_context 'reference_project_structure', { team_role: :owner }

  describe 'POST create' do
    let(:action) { post :create, params: params, format: :json }
    let(:params) { { protocol: { name: 'protocol_name' } } }

    it 'calls create activity for creating inventory column' do
      expect(Activities::CreateActivityService)
        .to(receive(:call)
              .with(hash_including(activity_type:
                                     :create_protocol_in_repository)))
      action
    end

    it 'adds activity in DB' do
      expect { action }
        .to(change { Activity.count })
    end
  end

  describe 'GET export' do
    let(:protocol) { create :protocol, :in_public_repository, team: team, added_by: user }
    let(:second_protocol) do
      create :protocol, :in_public_repository, team: team, added_by: user
    end
    let(:params) { { protocol_ids: [protocol.id, second_protocol.id] } }
    let(:action) { get :export, params: params }

    it 'calls create activity for exporting protocols' do
      expect(Activities::CreateActivityService)
        .to(receive(:call)
              .with(hash_including(activity_type:
                                     :export_protocol_in_repository))).twice
      action
    end

    it 'adds activity in DB' do
      expect { action }
        .to(change { Activity.count }.by(2))
    end
  end

  describe 'GET export from MyModule' do
    let(:protocol) { create :protocol, :in_public_repository, team: team, added_by: user }
    let(:params) { { protocol_ids: [protocol.id], my_module_id: my_module.id } }
    let(:action) { get :export, params: params }

    it 'calls create activity for exporting protocols' do
      expect(Activities::CreateActivityService)
        .to(receive(:call)
              .with(hash_including(activity_type:
                                     :export_protocol_from_task)))
      action
    end

    it 'adds activity in DB' do
      expect { action }
        .to(change { Activity.count }.by(1))
      expect(Activity.last.subject_type).to eq 'MyModule'
    end
  end

  describe 'POST import' do
    let(:params) do
      {
        team_id: team.id,
        type: 'public',
        # protocol: file_fixture('files/my_test_protocol.eln',
        #   'application/json'),
        # Not sure where should I attache file?
        protocol: {
          name: 'my_test_protocol',
          description: 'description',
          authors: 'authors',
          elnVersion: '1.0',
        }
      }
    end

    let(:action) { post :import, params: params, format: :json }

    it 'calls create activity for importing protocols' do
      expect(Activities::CreateActivityService)
        .to(receive(:call)
              .with(hash_including(activity_type:
                                     :import_protocol_in_repository)))
      action
    end

    it 'adds activity in DB' do
      expect { action }
        .to(change { Activity.count })
    end
  end

  describe 'PATCH description' do
    let(:protocol) do
      create :protocol, :in_repository_draft, team: team, added_by: user
    end
    let(:params) do
      {
        id: protocol.id,
        protocol: {
          description: 'description'
        }
      }
    end
    let(:action) { patch :update_description, params: params, format: :json }
    it 'calls create activity for updating description' do
      expect(Activities::CreateActivityService)
        .to(receive(:call)
              .with(hash_including(activity_type:
                                     :edit_description_in_protocol_repository)))
      action
    end

    it 'adds activity in DB' do
      expect { action }
        .to(change { Activity.count })
    end
  end

  describe 'PATCH update_keywords' do
    let(:protocol) do
      create :protocol, :in_repository_draft, team: team, added_by: user
    end
    let(:params) do
      { id: protocol.id, keywords: ['keyword-1', 'keyword-2'] }
    end
    let(:action) { patch :update_keywords, params: params, format: :json }

    it 'calls create activity for updating keywords' do
      expect(Activities::CreateActivityService)
        .to(receive(:call)
              .with(hash_including(activity_type:
                                     :edit_keywords_in_protocol_repository)))
      action
    end

    it 'adds activity in DB' do
      expect { action }
        .to(change { Activity.count })
    end
  end

  context 'update protocol' do
    let(:protocol_repo) do
      create :protocol, :in_repository_published_original, name: ' test protocol',
                                               team: team,
                                               added_by: user
    end
    let(:protocol) do
      create :protocol, :linked_to_repository, name: ' test protocol',
                                               my_module: my_module,
                                               parent: protocol_repo,
                                               team: team,
                                               added_by: user
    end
    let(:params) { { id: protocol.id } }

    describe 'POST revert' do
      let(:action) { post :revert, params: params, format: :json }

      it 'calls create activity for updating protocol in task from repository' do
        expect(Activities::CreateActivityService)
          .to(receive(:call)
                .with(hash_including(activity_type:
                                       :update_protocol_in_task_from_repository)))
        action
      end

      it 'adds activity in DB' do
        expect { action }
          .to(change { Activity.count })
      end
    end
  end

  describe 'POST load_from_repository' do
    let(:protocol_source) do
      create :protocol, :in_repository_published_original, team: team, added_by: user
    end
    let(:protocol) { create :protocol, team: team, added_by: user, my_module: my_module }
    let(:params) do
      { source_id: protocol_source.id, id: protocol.id }
    end
    let(:action) { post :load_from_repository, params: params, format: :json }

    it 'calls create activity for loading protocol to task from repository' do
      expect(Activities::CreateActivityService)
        .to(receive(:call)
              .with(hash_including(activity_type:
                                     :load_protocol_to_task_from_repository)))
      action
    end

    it 'adds activity in DB' do
      expect { action }
        .to(change { Activity.count })
    end
  end
end
