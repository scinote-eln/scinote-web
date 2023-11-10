# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::ProtocolTemplateController', type: :request do
  before :all do
    @user = create(:user)
    @another_user = create(:user)
    @team = create(:team, created_by: @user)
    @team2 = create(:team, created_by: @another_user)

    @protocol_draft = create(:protocol, :in_repository_draft, team: @team, added_by: @user)
    @protocol_published_original = create(:protocol, :in_repository_published_original, team: @team, added_by: @user)
    @protocol_published = create(:protocol, :in_repository_published_version, team: @team, added_by: @user, parent: @protocol_published_original, version_number: 2)
    @protocol_published_draft = create(:protocol, :in_repository_draft, team: @team, added_by: @user,
                                       parent: @protocol_published_original, version_number: 3, name: @protocol_published_original.name)

    @protocol_draft_second_team = create(:protocol, :in_repository_draft, team: @team2, added_by: @another_user)

    @valid_headers = { 'Authorization': 'Bearer ' + generate_token(@user.id) }
  end

  describe 'GET protocol template, #index' do
    it 'Response with correct protocol templates' do
      hash_body = nil
      get api_v1_team_protocol_templates_path(
        team_id: @team.id
      ), headers: @valid_headers
      expect { hash_body = json }.not_to raise_exception

      parsed_data = JSON.parse(
        ActiveModelSerializers::SerializableResource
          .new(Protocol.latest_available_versions(@team), each_serializer: Api::V1::ProtocolTemplateSerializer)
          .to_json
      )['data']

      expect(hash_body[:data]).to match_array(parsed_data)
    end

    it 'When invalid request, user in not member of the team' do
      hash_body = nil
      get api_v1_team_protocol_templates_path(
        team_id: @team2.id
      ), headers: @valid_headers

      expect(response).to have_http_status(403)
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body['errors'][0]).to include('status': 403)
    end

    it 'When invalid request, non existing team' do
      hash_body = nil
      get api_v1_team_protocol_templates_path(team_id: -1), headers: @valid_headers

      expect(response).to have_http_status(404)
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body['errors'][0]).to include('status': 404)
    end
  end

  describe 'GET protocol templates, #show' do
    it 'When valid request, user can read protocol template' do
      hash_body = nil
      get api_v1_team_protocol_template_path(id: @protocol_published_original.id, team_id: @team.id), headers: @valid_headers

      expect { hash_body = json }.not_to raise_exception
      parsed_data = JSON.parse(
        ActiveModelSerializers::SerializableResource
          .new(@protocol_published_original, serializer: Api::V1::ProtocolTemplateSerializer)
          .to_json
      )['data']

      expect(hash_body[:data]).to match_array(parsed_data)
    end

    it 'When invalid request, user in not member of the team' do
      hash_body = nil
      get api_v1_team_protocol_template_path(team_id: @team2.id,
                                              id: @protocol_published.id),
          headers: @valid_headers
      expect(response).to have_http_status(403)
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body['errors'][0]).to include('status': 403)
    end

    it 'When invalid request, non existing protocol template' do
      hash_body = nil
      get api_v1_team_protocol_template_path(team_id: @team.id, id: -1),
          headers: @valid_headers
      expect(response).to have_http_status(404)
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body['errors'][0]).to include('status': 404)
    end

    it 'When invalid request, protocol template from another team' do
      hash_body = nil
      get api_v1_team_protocol_template_path(team_id: @team.id,
                                             id: @protocol_draft_second_team.id),
          headers: @valid_headers
      expect(response).to have_http_status(404)
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body['errors'][0]).to include('status': 404)
    end
  end
end
