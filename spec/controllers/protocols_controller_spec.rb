# frozen_string_literal: true

require 'rails_helper'

describe ProtocolsController, type: :controller do
  login_user

  let(:user) { subject.current_user }
  let(:team) { create :team, created_by: user }
  let!(:user_team) { create :user_team, :admin, user: user, team: team }

  describe 'POST create' do
    let(:params) do
      {
        protocol: {
          name: 'protocol_name'
        }
      }
    end

    it 'calls create activity for creating inventory column' do
      expect(Activities::CreateActivityService)
        .to(receive(:call)
              .with(hash_including(activity_type:
                                     :create_protocol_in_repository)))

      post :create, params: params, format: :json
    end

    it 'adds activity in DB' do
      expect { post :create, params: params, format: :json }
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

  describe 'POST metadata' do
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
    let(:action) { put :update_metadata, params: params, format: :json }

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
end
