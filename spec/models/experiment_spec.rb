require 'rails_helper'

describe Experiment, type: :model do
  it 'should be of class Experiment' do
    expect(subject.class).to eq Experiment
  end

  describe 'Database table' do
    it { should have_db_column :id }
    it { should have_db_column :name }
    it { should have_db_column :description }
    it { should have_db_column :project_id }
    it { should have_db_column :created_by_id }
    it { should have_db_column :last_modified_by_id }
    it { should have_db_column :archived }
    it { should have_db_column :archived_by_id }
    it { should have_db_column :archived_on }
    it { should have_db_column :restored_by_id }
    it { should have_db_column :restored_on }
    it { should have_db_column :created_at }
    it { should have_db_column :updated_at }
    it { should have_db_column :workflowimg_file_name }
    it { should have_db_column :workflowimg_content_type }
    it { should have_db_column :workflowimg_file_size }
    it { should have_db_column :workflowimg_updated_at }
  end

  describe 'Relations' do
    it { should belong_to :project }
    it { should belong_to(:created_by).class_name('User') }
    it { should belong_to(:last_modified_by).class_name('User') }
    it { should belong_to(:archived_by).class_name('User') }
    it { should belong_to(:restored_by).class_name('User') }
    it { should have_many :my_modules }
    it { should have_many :my_module_groups }
    it { should have_many :report_elements }
    it { should have_many :activities }
  end

  describe 'Should be a valid object' do
    let(:project) { create :project }
    it { should validate_presence_of :project }
    it { should validate_presence_of :created_by }
    it { should validate_presence_of :last_modified_by }
    it do
      should validate_length_of(:name)
        .is_at_least(Constants::NAME_MIN_LENGTH)
        .is_at_most(Constants::NAME_MAX_LENGTH)
    end

    it do
      should validate_length_of(:description)
        .is_at_most(Constants::TEXT_MAX_LENGTH)
    end

    it 'should have uniq name scoped on project' do
      create :experiment, name: 'experiment',
                          project: project,
                          created_by: project.created_by,
                          last_modified_by: project.created_by
      new_exp = build_stubbed :experiment, name: 'experiment',
                                           project: project,
                                           created_by: project.created_by,
                                           last_modified_by: project.created_by
      expect(new_exp).to_not be_valid
    end
  end
end
