# frozen_string_literal: true

require 'rails_helper'

describe ExperimentsController, type: :controller do
  project_generator

  describe 'POST create' do
    let(:action) { post :create, params: params, format: :json }
    let(:params) do
      { project_id: @project[:project].id,
        experiment: { name: 'test experiment A1',
                      description: 'test description one' } }
    end

    it 'calls create activity service' do
      expect(Activities::CreateActivityService).to receive(:call)
        .with(hash_including(activity_type: :create_experiment))

      action
    end

    it 'adds activity in DB' do
      expect { action }
        .to(change { Activity.count })
    end
  end

  describe 'PUT update' do
    let(:action) { put :update, params: params }

    context 'when editing experiment' do
      let(:params) do
        {
          id: @project[:experiment].id,
          experiment: { title: 'new_title' }
        }
      end

      it 'calls create activity for editing experiment' do
        expect(Activities::CreateActivityService)
          .to(receive(:call)
                .with(hash_including(activity_type: :edit_experiment)))

        action
      end

      it 'adds activity in DB' do
        expect { action }
          .to(change { Activity.count })
      end
    end

    context 'when archiving experiment' do
      let(:archived_experiment) do
        create :experiment,
               archived: true,
               archived_by: (create :user),
               archived_on: Time.now,
               project: @project[:project]
      end

      let(:params) do
        {
          id: archived_experiment.id,
          experiment: { archived: false }
        }
      end

      it 'calls create activity for unarchiving experiment' do
        expect(Activities::CreateActivityService)
          .to(receive(:call)
            .with(hash_including(activity_type: :restore_experiment)))

        action
      end

      it 'adds activity in DB' do
        expect { action }
          .to(change { Activity.count })
      end
    end
  end

  describe 'GET archive' do
    let(:action) { get :archive, params: params, format: :json }
    let(:params) do
      { id: @project[:experiment].id,
        experiment: { archived: false } }
    end
    it 'calls create activity service' do
      expect(Activities::CreateActivityService).to receive(:call)
        .with(hash_including(activity_type: :archive_experiment))

      action
    end

    it 'adds activity in DB' do
      expect { action }
        .to(change { Activity.count })
    end
  end
end
