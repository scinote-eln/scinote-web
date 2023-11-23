# frozen_string_literal: true

require 'rails_helper'

describe MyModuleStatusFlow, type: :model do
  let(:my_module_global_workflow) { build :my_module_status_flow }
  let(:my_module_team_workflow) { build :my_module_status_flow, :in_team }

  it 'is valid' do
    expect(my_module_global_workflow).to be_valid
  end

  it 'should be of class MyModuleStatusFlow' do
    expect(subject.class).to eq MyModuleStatusFlow
  end

  describe 'Database table' do
    it { should have_db_column :name }
    it { should have_db_column :description }
    it { should have_db_column :visibility }
    it { should have_db_column :created_by_id }
    it { should have_db_column :last_modified_by_id }
    it { should have_db_column :created_at }
    it { should have_db_column :updated_at }
  end

  describe 'Relations' do
    it { should have_many(:my_module_statuses).dependent(:destroy) }
  end

  describe 'Validations' do
    describe '#visibility' do
      it { is_expected.to validate_presence_of :visibility }
    end

    describe '#name' do
      it { is_expected.to validate_length_of(:name).is_at_most(Constants::NAME_MAX_LENGTH) }
      it { expect(my_module_team_workflow).to validate_uniqueness_of(:name).scoped_to(:team_id).case_insensitive }
    end

    describe '#description' do
      it { is_expected.to validate_length_of(:description).is_at_most(Constants::TEXT_MAX_LENGTH) }
    end

    describe '#team' do
      it { expect(my_module_team_workflow).to validate_presence_of :team }
    end
  end

  describe 'self.ensure_default' do
    context 'when there is no global flow' do
      it 'adds new global workflow' do
        initial_global_count = MyModuleStatusFlow.global.count
        initial_module_status_count = MyModuleStatus.count
        method_result = described_class.ensure_default

        expect(MyModuleStatusFlow.global.count - initial_global_count).to eq(1)
        expect(MyModuleStatus.count - initial_module_status_count).to eq(method_result.count)
      end
    end

    context 'when there is global flow' do
      it 'adds new global workflow' do
        described_class.ensure_default

        expect { described_class.ensure_default }.not_to(change { MyModuleStatusFlow.global.count })
      end
    end
  end
end
