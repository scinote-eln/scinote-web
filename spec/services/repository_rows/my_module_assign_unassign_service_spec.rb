# frozen_string_literal: true

require 'rails_helper'

describe RepositoryRows::MyModuleAssignUnassignService do
  let(:user) { create :user }
  let(:team) { create :team, created_by: user }
  let(:project) { create(:project, team:, created_by: user) }
  let(:experiment) { create(:experiment, :with_tasks, project:) }
  let(:my_module) { create(:my_module, experiment:) }

  let(:repository) { create :repository, team:, created_by: user }
  let(:rows) do
    create_list(:repository_row, 10, repository:) do |row, i|
      row.name = "My Row (#{i + 1})"
    end
  end
  let(:service_call) { described_class.call(**valid_attributes) }
  let(:valid_attributes) do
    {
      my_module:,
      repository:,
      user:,
      params:
    }
  end
  let(:rows_to_assign) { rows.take(6).pluck(:id) }
  let(:rows_to_unassign) { repository.repository_rows.where.not(id: rows_to_assign).order(:id).pluck(:id) }

  context 'single module' do
    context 'assigning items' do
      let(:rows_to_assign) { rows.take(6).pluck(:id) }
      let(:rows_to_unassign) { repository.repository_rows.where.not(id: rows_to_assign).order(:id).pluck(:id) }
      let(:params) do
        {
          rows_to_assign:,
          rows_to_unassign:,
          downstream: false
        }
      end

      it 'creates a new assignment' do
        expect { service_call }.to change { MyModuleRepositoryRow.count }.by rows_to_assign.count
      end

      it 'unassigns and assigns items' do
        rows_to_unassign.each do |row_id|
          my_module.my_module_repository_rows.create!(repository_row_id: row_id, assigned_by: user)
        end

        service_call
        expect(
          my_module.my_module_repository_rows.order(:repository_row_id).pluck(:repository_row_id)
        ).to eq rows_to_assign
      end

      it 'does nothing' do
        rows_to_assign.each do |row_id|
          my_module.my_module_repository_rows.create!(repository_row_id: row_id, assigned_by: user)
        end

        expect { service_call }.to change { MyModuleRepositoryRow.count }.by 0
      end
    end

    context 'unassigning' do
      let(:params) do
        {
          rows_to_assign: [],
          rows_to_unassign: rows.pluck(:id),
          downstream: false
        }
      end
      let(:rows_to_assign) { [] }
      let(:rows_to_unassign) { rows.pluck(:id) }
      it 'unassigns items' do
        rows_to_unassign.each do |row_id|
          my_module.my_module_repository_rows.create!(repository_row_id: row_id, assigned_by: user)
        end
        initial_count = my_module.my_module_repository_rows.count

        service_call
        expect(my_module.my_module_repository_rows.count).to eq 0
        expect(my_module.my_module_repository_rows.count).to_not eq initial_count
      end
    end
  end
end
