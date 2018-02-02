require 'rails_helper'

describe MyModule, type: :model do
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
    it { should belong_to :experiment }
    it { should belong_to :my_module_group }
    it { should belong_to(:created_by).class_name('User') }
    it { should belong_to(:last_modified_by).class_name('User') }
    it { should belong_to(:archived_by).class_name('User') }
    it { should belong_to(:restored_by).class_name('User') }
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

  describe 'Should be a valid object' do
    it { should validate_presence_of :x }
    it { should validate_presence_of :y }
    it { should validate_presence_of :workflow_order }
    it { should validate_presence_of :experiment }
    it do
      should validate_length_of(:name)
        .is_at_least(Constants::NAME_MIN_LENGTH)
        .is_at_most(Constants::NAME_MAX_LENGTH)
    end
    it do
      should validate_length_of(:description)
        .is_at_most(Constants::TEXT_MAX_LENGTH)
    end
  end
end
