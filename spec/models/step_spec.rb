# frozen_string_literal: true

require 'rails_helper'

describe Step, type: :model do
  let(:step) { build :step }

  it 'is valid' do
    expect(step).to be_valid
  end

  it 'should be of class Step' do
    expect(subject.class).to eq Step
  end

  describe 'Database table' do
    it { should have_db_column :name }
    it { should have_db_column :description }
    it { should have_db_column :position }
    it { should have_db_column :completed }
    it { should have_db_column :completed_on }
    it { should have_db_column :user_id }
    it { should have_db_column :created_at }
    it { should have_db_column :updated_at }
    it { should have_db_column :last_modified_by_id }
    it { should have_db_column :protocol_id }
  end

  describe 'Relations' do
    it { should belong_to :user }
    it { should belong_to :protocol }
    it { should belong_to(:last_modified_by).class_name('User').optional }
    it { should have_many :checklists }
    it { should have_many :step_comments }
    it { should have_many :step_assets }
    it { should have_many :assets }
    it { should have_many :step_tables }
    it { should have_many :tables }
    it { should have_many :report_elements }
    it { should have_many :tiny_mce_assets }
  end

  describe 'Validations' do
    it { should validate_presence_of :name }
    it { should validate_presence_of :position }
    it { should validate_presence_of :user }
    it { should validate_presence_of :protocol }
    it do
      should validate_length_of(:name).is_at_most(Constants::NAME_MAX_LENGTH)
    end
    it do
      should validate_length_of(:description)
        .is_at_most(Constants::RICH_TEXT_MAX_LENGTH)
    end
    it { should validate_inclusion_of(:completed).in_array([true, false]) }
  end
end
