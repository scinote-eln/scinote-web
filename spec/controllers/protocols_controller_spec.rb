# frozen_string_literal: true

require 'rails_helper'

describe ProtocolsController, type: :controller do
  login_user

  let(:user) { subject.current_user }
  let(:team) { create :team, created_by: user }
  let!(:user_team) { create :user_team, :admin, user: user, team: team }
  let(:project) { create :project, team: team, created_by: user }
  let!(:user_project) do
    create :user_project, :normal_user, user: user, project: project
  end
  let(:experiment) { create :experiment, project: project }
  let(:my_module) { create :my_module, experiment: experiment }

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
    let(:protocol) { create :protocol, :in_public_repository, team: team }
    let(:second_protocol) do
      create :protocol, :in_public_repository, team: team
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
    let(:protocol) { create :protocol, :in_public_repository, team: team }
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
        # protocol: fixture_file_upload('files/my_test_protocol.eln',
        #   'application/json'),
        # Not sure where should I attache file?
        protocol: {
          name: 'my_test_protocol',
          description: 'description',
          authors: 'authors'
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

  describe 'PUT description' do
    let(:protocol) do
      create :protocol, :in_public_repository, team: team, added_by: user
    end
    let(:params) do
      {
        id: protocol.id,
        protocol: {
          description: 'description'
        }
      }
    end
    let(:action) { put :update_description, params: params, format: :json }

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

  describe 'POST update_keywords' do
    let(:protocol) do
      create :protocol, :in_public_repository, team: team, added_by: user
    end
    let(:action) { put :update_keywords, params: params, format: :json }
    let(:params) do
      { id: protocol.id, keywords: ['keyword-1', 'keyword-2'] }
    end

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
      create :protocol, :in_public_repository, name: ' test protocol',
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
      let(:action) { put :revert, params: params, format: :json }

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

    describe 'POST update_parent' do
      let(:action) { put :update_parent, params: params, format: :json }

      it 'calls create activity for updating protocol in repository from task' do
        expect(Activities::CreateActivityService)
          .to(receive(:call)
                .with(hash_including(activity_type:
                                       :update_protocol_in_repository_from_task)))
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
      create :protocol, :in_public_repository, team: team, added_by: user
    end
    let(:protocol) { create :protocol, team: team, added_by: user }
    let(:action) { put :load_from_repository, params: params, format: :json }
    let(:params) do
      { source_id: protocol_source.id, id: protocol.id }
    end

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

  describe 'POST load_from_file' do
    let(:protocol) do
      create :protocol, my_module: my_module, team: team, added_by: user
    end
    let(:action) { put :load_from_file, params: params, format: :json }
    let(:params) do
      { id: protocol.id,
        protocol: { name: 'my_test_protocol',
                    description: 'description',
                    authors: 'authors' } }
    end

    it 'calls create activity for loading protocol to task from file' do
      expect(Activities::CreateActivityService)
        .to(receive(:call)
              .with(hash_including(activity_type:
                                     :load_protocol_to_task_from_file)))
      action
    end

    it 'adds activity in DB' do
      expect { action }
        .to(change { Activity.count })
    end
  end
end
