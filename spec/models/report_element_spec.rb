require 'rails_helper'

describe ReportElement, type: :model do
  it 'should be of class ReportElement' do
    expect(subject.class).to eq ReportElement
  end

  describe 'Database table' do
    it { should have_db_column :position }
    it { should have_db_column :type_of }
    it { should have_db_column :sort_order }
    it { should have_db_column :report_id }
    it { should have_db_column :parent_id }
    it { should have_db_column :project_id }
    it { should have_db_column :my_module_id }
    it { should have_db_column :step_id }
    it { should have_db_column :result_id }
    it { should have_db_column :checklist_id }
    it { should have_db_column :asset_id }
    it { should have_db_column :table_id }
    it { should have_db_column :created_at }
    it { should have_db_column :updated_at }
    it { should have_db_column :experiment_id }
    it { should have_db_column :repository_id }
  end

  describe 'Relations' do
    it { should belong_to :report }
    it { should belong_to :project }
    it { should belong_to :experiment }
    it { should belong_to :my_module }
    it { should belong_to :step }
    it { should belong_to :result }
    it { should belong_to :checklist }
    it { should belong_to :asset }
    it { should belong_to :table }
    it { should belong_to :repository }
    it { should belong_to(:report) }
    it { should have_many(:children).class_name('ReportElement') }
  end

  describe 'Should be a valid object' do
    it { should validate_presence_of :position }
    it { should validate_presence_of :report }
    it { should validate_presence_of :type_of }
  end
end
