# frozen_string_literal: true

require 'rails_helper'

describe StepsController, type: :controller do
  login_user

  let(:user) { subject.current_user }
  let(:team) { create :team, created_by: user }
  let!(:user_team) { create :user_team, :admin, user: user, team: team }
  let(:protocol) do
    create :protocol, :in_public_repository, team: team, added_by: user
  end
  let(:step) { create :step, protocol: protocol }

  describe 'POST create' do
    context 'when in protocol repository' do
      let(:params) do
        {
          protocol_id: protocol.id,
          step: {
            name: 'test',
            description: 'description'
          }
        }
      end
      let(:action) { post :create, params: params, format: :json }

      it 'calls create activity for creating step in protocol repository' do
        expect(Activities::CreateActivityService)
          .to(receive(:call)
                .with(hash_including(activity_type:
                                       :add_step_to_protocol_repository)))

        action
      end

      it 'adds activity in DB' do
        expect { action }
          .to(change { Activity.count })
      end
    end
  end

  describe 'PUT update' do
    context 'when in protocol repository' do
      let(:params) do
        {
          id: step.id,
          protocol_id: protocol.id,
          step: {
            name: 'updated name',
            description: 'updated description'
          }
        }
      end
      let(:action) { put :update, params: params, format: :json }

      it 'calls create activity for editing step in protocol repository' do
        expect(Activities::CreateActivityService)
          .to(receive(:call)
                .with(hash_including(activity_type:
                                       :edit_step_in_protocol_repository)))

        action
      end

      it 'adds activity in DB' do
        expect { action }
          .to(change { Activity.count })
      end
    end
  end

  describe 'DELETE destroy' do
    context 'when in protocol repository' do
      let(:params) { { id: step.id } }
      let(:action) { delete :destroy, params: params, format: :json }

      it 'calls create activity for deleting step in protocol repository' do
        expect(Activities::CreateActivityService)
          .to(receive(:call)
                .with(hash_including(activity_type:
                                       :delete_step_in_protocol_repository)))

        action
      end

      it 'adds activity in DB' do
        expect { action }
          .to(change { Activity.count })
      end
    end
  end
end
