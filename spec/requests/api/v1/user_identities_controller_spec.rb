# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::UsersIdentitiesController', type: :request do
  before :all do
    @user1 = create(:user, email: Faker::Internet.unique.email)
    @user2 = create(:user, email: Faker::Internet.unique.email)
    create(:user_identity, user: @user1,
           uid: Faker::Crypto.unique.sha1, provider: Faker::App.unique.name)
    @valid_headers =
      { 'Authorization': 'Bearer ' + generate_token(@user1.id) }
  end

  describe 'GET user_identities, #index' do
    it 'When valid request, requested identities for current user' do
      hash_body = nil
      get api_v1_user_identities_path(user_id: @user1.id),
          headers: @valid_headers
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body[:data]).to match(
        ActiveModelSerializers::SerializableResource
          .new(@user1.user_identities,
               each_serializer: Api::V1::UserIdentitySerializer)
          .as_json[:data]
      )
    end

    it 'When invalid request, requested user is not signed in user' do
      hash_body = nil
      get api_v1_user_identities_path(user_id: @user2.id),
          headers: @valid_headers
      expect(response).to have_http_status(403)
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body['errors'][0]).to include('status': 403)
    end

    it 'When invalid request, non existing user' do
      hash_body = nil
      get api_v1_user_identities_path(user_id: 123),
          headers: @valid_headers
      expect(response).to have_http_status(403)
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body['errors'][0]).to include('status': 403)
    end
  end

  describe 'POST user_identities, #create' do
    it 'When valid request, create new identity for current user' do
      hash_body = nil
      post api_v1_user_identities_path(user_id: @user1.id),
           params: {
             data: { type: 'user_identities',
                     attributes: { uid: Faker::Crypto.unique.sha1,
                                   provider: Faker::App.unique.name } }
           },
           headers: @valid_headers
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body[:data]).to match(
        ActiveModelSerializers::SerializableResource
          .new(@user1.user_identities.order(:id).last,
               serializer: Api::V1::UserIdentitySerializer)
          .as_json[:data]
      )
    end
  end

  describe 'GET user_identity, #show' do
    it 'When valid request, requested specific identity for current user' do
      hash_body = nil
      get api_v1_user_identity_path(
        user_id: @user1.id, id: @user1.user_identities.order(:id).last
      ), headers: @valid_headers
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body[:data]).to match(
        ActiveModelSerializers::SerializableResource
          .new(@user1.user_identities.order(:id).last,
               serializer: Api::V1::UserIdentitySerializer)
          .as_json[:data]
      )
    end
  end

  describe 'PUT user_identities, #update' do
    it 'When valid request, update identity for current user' do
      hash_body = nil
      put api_v1_user_identity_path(user_id: @user1.id,
            id: @user1.user_identities.order(:id).last),
          params: {
            data: { id: @user1.user_identities.order(:id).last.id,
                    type: 'user_identities',
                    attributes: { uid: Faker::Crypto.unique.sha1 } }
          },
          headers: @valid_headers
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body[:data]).to match(
        ActiveModelSerializers::SerializableResource
          .new(@user1.user_identities.order(:id).last,
               serializer: Api::V1::UserIdentitySerializer)
          .as_json[:data]
      )
    end
  end

  describe 'DELETE user_identity, #destroy' do
    it 'When valid request, destroy specified identity for current user' do
      identity = @user1.user_identities.order(:id).last
      delete api_v1_user_identity_path(user_id: @user1.id, id: identity),
             headers: @valid_headers
      expect(response).to have_http_status(200)
      expect(response.body).to eq('')
      expect(UserIdentity.find_by_id(identity.id)).to eq(nil)
    end
  end
end
