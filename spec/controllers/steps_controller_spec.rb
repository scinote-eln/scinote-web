# frozen_string_literal: true

require 'rails_helper'

describe StepsController, type: :controller do
  login_user

  include_context 'reference_project_structure', {
    step: true
  }

  let(:protocol_repo) do
    create :protocol, :in_repository_draft, team: team, added_by: user
  end
  let(:step_repo) { create :step, protocol: protocol_repo }

  describe 'POST create' do
    let(:action) { post :create, params: params, format: :json }

    context 'when in protocol repository' do
      let(:params) do
        { protocol_id: protocol_repo.id,
          step: { name: 'test', description: 'description' }, position: 1 }
      end

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

    context 'when in protocol on task' do
      let(:params) do
        { protocol_id: my_module.protocol.id,
          step: { name: 'test', description: 'description' }, position: 1 }
      end

      it 'calls create activity for creating step in protocol on task' do
        expect(Activities::CreateActivityService)
          .to(receive(:call)
                .with(hash_including(activity_type: :create_step)))
        action
      end

      it 'adds activity in DB' do
        expect { action }
          .to(change { Activity.count })
      end
    end
  end

  describe 'PUT update' do
    let(:action) { put :update, params: params, format: :json }

    context 'when in protocol repository' do
      let(:params) do
        {
          id: step_repo.id,
          protocol_id: protocol_repo.id,
          step: {
            name: 'updated name',
            description: 'updated description'
          }
        }
      end

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

    context 'when in protocol on task' do
      let(:params) do
        { id: step.id,
          step: { name: 'updated name', description: 'updated description' } }
      end

      it 'calls create activity for editing step in protocol on task' do
        expect(Activities::CreateActivityService)
          .to(receive(:call)
                .with(hash_including(activity_type: :edit_step)))
        action
      end

      it 'adds activity in DB' do
        expect { action }
          .to(change { Activity.count })
      end
    end
  end

  describe 'DELETE destroy' do
    let(:action) { delete :destroy, params: params, format: :json }

    context 'when in protocol repository' do
      let(:params) { { id: step_repo.id } }

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

    context 'when in protocol on task' do
      let(:params) { { id: step.id } }

      it 'calls create activity for deleting step in protocol on task' do
        expect(Activities::CreateActivityService)
          .to(receive(:call)
                .with(hash_including(activity_type: :destroy_step)))
        action
      end

      it 'adds activity in DB' do
        expect { action }
          .to(change { Activity.count })
      end
    end
  end

  describe 'POST toggle_step_state' do
    let(:action) { post :toggle_step_state, params: params, format: :json }

    context 'when completing step' do
      let(:step) do
        create :step, protocol: my_module.protocol, user: user, completed: false
      end
      let(:params) { { id: step.id, completed: true } }

      it 'calls create activity for completing step' do
        expect(Activities::CreateActivityService)
          .to(receive(:call)
                .with(hash_including(activity_type: :complete_step)))
        action
      end

      it 'adds activity in DB' do
        expect { action }
          .to(change { Activity.count })
      end
    end

    context 'when uncompleting step' do
      let(:params) { { id: step.id, completed: false } }

      it 'calls create activity for uncompleting step' do
        expect(Activities::CreateActivityService)
          .to(receive(:call)
                .with(hash_including(activity_type: :uncomplete_step)))
        action
      end

      it 'adds activity in DB' do
        expect { action }
          .to(change { Activity.count })
      end
    end
  end
end
