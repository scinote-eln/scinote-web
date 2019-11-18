# frozen_string_literal: true

require 'rails_helper'

describe MyModule, type: :model do
  let(:my_module) { build :my_module }

  it 'is valid' do
    expect(my_module).to be_valid
  end

  it 'should be of class MyModule' do
    expect(subject.class).to eq MyModule
  end

  describe 'Database table' do
    it { should have_db_column :id }
    it { should have_db_column :name }
    it { should have_db_column :due_date }
    it { should have_db_column :description }
    it { should have_db_column :x }
    it { should have_db_column :y }
    it { should have_db_column :my_module_group_id }
    it { should have_db_column :created_at }
    it { should have_db_column :updated_at }
    it { should have_db_column :archived }
    it { should have_db_column :archived_on }
    it { should have_db_column :created_by_id }
    it { should have_db_column :last_modified_by_id }
    it { should have_db_column :archived_by_id }
    it { should have_db_column :restored_by_id }
    it { should have_db_column :restored_on }
    it { should have_db_column :nr_of_assigned_samples }
    it { should have_db_column :workflow_order }
    it { should have_db_column :experiment_id }
    it { should have_db_column :state }
    it { should have_db_column :completed_on }
  end

  describe 'Relations' do
    it { should belong_to(:experiment) }
    it { should belong_to(:my_module_group).optional }
    it { should belong_to(:created_by).class_name('User').optional }
    it { should belong_to(:last_modified_by).class_name('User').optional }
    it { should belong_to(:archived_by).class_name('User').optional }
    it { should belong_to(:restored_by).class_name('User').optional }
    it { should have_many :results }
    it { should have_many :my_module_tags }
    it { should have_many :tags }
    it { should have_many :task_comments }
    it { should have_many :my_modules }
    it { should have_many :sample_my_modules }
    it { should have_many :samples }
    it { should have_many :my_module_repository_rows }
    it { should have_many :repository_rows }
    it { should have_many :user_my_modules }
    it { should have_many :users }
    it { should have_many :activities }
    it { should have_many :report_elements }
    it { should have_many :protocols }
    it { should have_many(:inputs).class_name('Connection') }
    it { should have_many(:outputs).class_name('Connection') }
    it { should have_many(:my_module_antecessors).class_name('MyModule') }
  end

  describe 'Validations' do
    describe '#name' do
      it do
        is_expected.to(validate_length_of(:name)
                         .is_at_least(Constants::NAME_MIN_LENGTH)
                         .is_at_most(Constants::NAME_MAX_LENGTH))
      end
    end

    describe '#description' do
      it do
        is_expected.to(validate_length_of(:description)
                         .is_at_most(Constants::RICH_TEXT_MAX_LENGTH))
      end
    end

    describe '#x, #y scoped to experiment for active modules' do
      it { is_expected.to validate_presence_of :x }
      it { is_expected.to validate_presence_of :y }

      it 'should be invalid for same x, y, and experiment' do
        my_module.save
        new_my_module = my_module.dup

        expect(new_my_module).not_to be_valid
      end

      it 'should be valid when module with same x, y and expriment is archived' do
        my_module.save
        new_my_module = my_module.dup
        my_module.update_column(:archived, true)

        expect(new_my_module).to be_valid
      end
    end

    describe '#workflow_order' do
      it { is_expected.to validate_presence_of :workflow_order }
    end

    describe '#experiment' do
      it { is_expected.to validate_presence_of :experiment }
    end
  end
end
