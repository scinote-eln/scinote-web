# frozen_string_literal: true

require 'rails_helper'

describe RepositoryCellsController, type: :controller do
  login_user
  let!(:user) { controller.current_user }
  let!(:team) { create :team, created_by: user }
  let!(:viewer_role) { create :viewer_role }
  let!(:repository) { create :repository, team: team, created_by: user }
  let!(:repository_row) do
    create :repository_row, repository: repository, created_by: user, last_modified_by: user
  end
  let!(:repository_column) { create :repository_column, :text_type, repository: repository, created_by: user }

  let!(:user_two) { create :user, email: 'new@user.com' }
  let!(:team_two) { create :team, created_by: user_two }
  let!(:repository_two) { create :repository, team: team_two, created_by: user_two }

  describe 'POST update' do
    let(:action) { post :update, params: params, format: :json }
    let(:params) do
      {
        repository_id: repository.id,
        repository_row_id: repository_row.id,
        repository_column_id: repository_column.id,
        value: 'new value'
      }
    end

    context 'when the cell does not exist yet' do
      it 'creates a new repository cell' do
        expect { action }.to change { repository_row.reload.repository_cells.count }.by(1)
      end

      it 'sets the given value on the created cell' do
        action
        cell = repository_row.reload.repository_cells.find_by(repository_column: repository_column)
        expect(cell.value.data).to eq('new value')
      end

      it 'renders a success response' do
        action
        expect(response).to have_http_status(:success)
      end

      it 'logs an edit_item_inventory activity' do
        expect(Activities::CreateActivityService)
          .to(receive(:call).with(hash_including(activity_type: :edit_item_field_inventory)))

        action
      end

      it 'adds an activity in the DB' do
        expect { action }.to(change { Activity.count })
      end

      context 'when the value is blank' do
        let(:params) do
          {
            repository_id: repository.id,
            repository_row_id: repository_row.id,
            repository_column_id: repository_column.id,
            value: ''
          }
        end

        it 'does not create a repository cell' do
          expect { action }.not_to(change { RepositoryCell.count })
        end

        it 'does not log an activity' do
          expect(Activities::CreateActivityService).not_to receive(:call)

          action
        end
      end
    end

    context 'when the cell already exists' do
      let!(:repository_cell) do
        create :repository_cell, :text_value, repository_row: repository_row, repository_column: repository_column
      end

      context 'and the new value is different' do
        it 'updates the value of the existing cell' do
          action
          expect(repository_cell.value.reload.data).to eq('new value')
        end

        it 'does not create a new repository cell' do
          expect { action }.not_to(change { RepositoryCell.count })
        end

        it 'logs an edit_item_inventory activity' do
          expect(Activities::CreateActivityService)
            .to(receive(:call).with(hash_including(activity_type: :edit_item_field_inventory)))

          action
        end
      end

      context 'and the new value is blank' do
        let(:params) do
          {
            repository_id: repository.id,
            repository_row_id: repository_row.id,
            repository_column_id: repository_column.id,
            value: ''
          }
        end

        it 'destroys the existing cell' do
          expect { action }.to(change { RepositoryCell.count }.by(-1))
        end

        it 'logs an edit_item_inventory activity' do
          expect(Activities::CreateActivityService)
            .to(receive(:call).with(hash_including(activity_type: :edit_item_field_inventory)))

          action
        end
      end

      context 'and the new value is the same' do
        let(:params) do
          {
            repository_id: repository.id,
            repository_row_id: repository_row.id,
            repository_column_id: repository_column.id,
            value: repository_cell.value.data
          }
        end

        it 'does not log an activity' do
          expect(Activities::CreateActivityService).not_to receive(:call)

          action
        end
      end
    end

    context 'when the value contains a smart annotation mention' do
      let!(:mentioned_user) { create :user, email: 'mentioned@user.com' }
      let(:params) do
        {
          repository_id: repository.id,
          repository_row_id: repository_row.id,
          repository_column_id: repository_column.id,
          value: "Hello [@#{mentioned_user.full_name}~#{mentioned_user.id.base62_encode}]"
        }
      end

      it 'sends a smart annotation notification to the mentioned user' do
        expect(GeneralNotification).to(
          receive(:send_notifications).with(hash_including(type: :smart_annotation_added, user_id: mentioned_user.id))
        )

        action
      end

      context 'when updating an existing text cell' do
        let!(:repository_cell) do
          create :repository_cell, :text_value, repository_row: repository_row, repository_column: repository_column
        end

        it 'sends a smart annotation notification to the mentioned user' do
          expect(GeneralNotification).to(
            receive(:send_notifications).with(hash_including(type: :smart_annotation_added, user_id: mentioned_user.id))
          )

          action
        end
      end
    end

    context 'when the column is a date column with a reminder and reminders are enabled' do
      # Noon UTC keeps the rounded-up days_left away from day boundaries
      around do |example|
        Timecop.freeze(Time.utc(2025, 1, 15, 12, 0, 0)) do
          example.run
        end
      end

      # Repository.reminders_enabled? delegates to stock management
      before { allow(RepositoryBase).to receive(:stock_management_enabled?).and_return(true) }

      let!(:date_column) do
        create :repository_column, :date_type, repository: repository,
                                               created_by: user,
                                               metadata: { 'reminder_value' => '5',
                                                           'reminder_unit' => '86400',
                                                           'reminder_message' => 'Check expiry' }
      end
      let(:params) do
        {
          repository_id: repository.id,
          repository_row_id: repository_row.id,
          repository_column_id: date_column.id,
          value: date
        }
      end
      let(:response_value) { JSON.parse(response.body)['value'] }

      context 'and the date is inside the reminder window' do
        let(:date) { '2025-01-17' }

        it 'renders an active reminder with the days left' do
          action
          expect(response_value).to include('reminder' => true, 'days_left' => 2, 'reminder_message' => 'Check expiry')
          expect(response_value['reminder_text']).to be_present
        end
      end

      context 'and the date has passed' do
        let(:date) { '2025-01-12' }

        it 'renders an expired reminder' do
          action
          expect(response_value['reminder']).to be(true)
          expect(response_value).not_to have_key('days_left')
          expect(response_value['reminder_text']).to eq(I18n.t('repositories.item_card.reminders.item_expired'))
        end
      end

      context 'and the date is outside the reminder window' do
        let(:date) { '2025-02-14' }

        it 'renders an inactive reminder' do
          action
          expect(response_value['reminder']).to be(false)
        end
      end
    end

    context 'when the repository is not visible to the user' do
      let(:params) do
        {
          repository_id: repository_two.id,
          repository_row_id: repository_row.id,
          repository_column_id: repository_column.id,
          value: 'new value'
        }
      end

      it 'renders 404' do
        action
        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when the repository row does not belong to the repository' do
      let!(:repository_row_two) do
        create :repository_row, repository: repository_two, created_by: user_two, last_modified_by: user_two
      end
      let(:params) do
        {
          repository_id: repository.id,
          repository_row_id: repository_row_two.id,
          repository_column_id: repository_column.id,
          value: 'new value'
        }
      end

      it 'renders 404' do
        action
        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when the column does not belong to the repository' do
      let!(:other_repository_column) { create :repository_column, :text_type, repository: repository_two, created_by: user_two }
      let(:params) do
        {
          repository_id: repository.id,
          repository_row_id: repository_row.id,
          repository_column_id: other_repository_column.id,
          value: 'new value'
        }
      end

      it 'renders 404' do
        action
        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when the user does not have manage permissions' do
      before { repository.user_assignments.update(user_role: viewer_role) }

      it 'renders 403' do
        action
        expect(response).to have_http_status(:forbidden)
      end

      it 'does not create a repository cell' do
        expect { action }.not_to(change { RepositoryCell.count })
      end
    end
  end
end
