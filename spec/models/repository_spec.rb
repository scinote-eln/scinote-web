# frozen_string_literal: true

require 'rails_helper'

describe Repository, type: :model do
  let(:repository) { build :repository }

  it 'is valid' do
    expect(repository).to be_valid
  end

  it 'should be of class Repository' do
    expect(subject.class).to eq Repository
  end

  describe 'Database table' do
    it { should have_db_column :team_id }
    it { should have_db_column :created_by_id }
    it { should have_db_column :name }
    it { should have_db_column :created_at }
    it { should have_db_column :updated_at }
  end

  describe 'Relations' do
    it { should belong_to :team }
    it { should belong_to(:created_by).class_name('User') }
    it { should have_many :repository_rows }
    it { should have_many :repository_table_states }
    it { should have_many :report_elements }
    it { should have_many(:repository_list_items).dependent(:destroy) }
    it { should have_many(:team_repositories).dependent(:destroy) }
    it { should have_many(:teams_shared_with) }
  end

  describe 'Validations' do
    describe '#created_by' do
      it { is_expected.to validate_presence_of :created_by }
    end

    describe '#name' do
      it { is_expected.to validate_length_of(:name).is_at_most(Constants::NAME_MAX_LENGTH) }
      it { expect(repository).to validate_uniqueness_of(:name).scoped_to(:team_id).case_insensitive }
    end

    describe '#team' do
      it { is_expected.to validate_presence_of :team }
    end
  end

  describe '.copy' do
    let(:created_by) { create :user }
    let(:repository) { create :repository }

    it 'calls create activity for copying inventory' do
      expect(Activities::CreateActivityService)
        .to(receive(:call).with(hash_including(activity_type: :copy_inventory)))

      repository.copy(created_by, 'name for copied repo')
    end

    it 'adds activity in DB' do
      expect { repository.copy(created_by, 'name for copied repo') }
        .to(change { Activity.count })
    end
  end
end
