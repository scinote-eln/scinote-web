# frozen_string_literal: true

require 'rails_helper'

describe Activity, type: :model do
  subject(:activity) { create :activity }
  let(:old_activity) { create :activity, :old }

  it 'should be of class Activity' do
    expect(subject.class).to eq Activity
  end

  it 'is valid' do
    expect(activity).to be_valid
  end

  it 'is valid (old)' do
    expect(old_activity).to be_valid
  end

  describe 'Database table' do
    it { should have_db_column :id }
    it { should have_db_column :my_module_id }
    it { should have_db_column :owner_id }
    it { should have_db_column :type_of }
    it { should have_db_column :message }
    it { should have_db_column :created_at }
    it { should have_db_column :updated_at }
    it { should have_db_column :project_id }
    it { should have_db_column :experiment_id }
  end

  describe 'Relations' do
    it { should belong_to :project }
    it { should belong_to :experiment }
    it { should belong_to :my_module }
    it { should belong_to :owner }
    it { should belong_to :subject }
  end

  describe 'Validations' do
    it { should validate_presence_of :type_of }
    it { should validate_presence_of :owner }

    Extends::ACTIVITY_SUBJECT_TYPES.each do |value|
      it { is_expected.to allow_values(value).for(:subject_type) }
    end
  end

  describe '.old_activity?' do
    it 'returns true for old activity' do
      expect(old_activity.old_activity?).to be_truthy
    end
    it 'returns false for activity' do
      expect(activity.old_activity?).to be_falsey
    end
  end

  describe '.save' do
    it 'adds user to message items' do
      create :activity

      expect(activity.message_items).to include(user: be_an(Hash))
    end
  end
end
