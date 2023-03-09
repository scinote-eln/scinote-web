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
    it { should have_many(:team_shared_objects).dependent(:destroy) }
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

  describe 'Scopes' do
    let(:user) { create :user }

    describe '#active and #archived' do
      before do
        create :repository, created_by: user
        create :repository, :archived, created_by: user
      end

      it 'returns only active rows' do
        expect(Repository.active.count).to be_eql 1
      end

      it 'returns only archived rows' do
        expect(Repository.archived.count).to be_eql 1
      end

      it 'returns all rows' do
        expect(Repository.count).to be_eql 2
      end
    end
  end

  describe '.copy' do
    let(:user) { create :user }
    let(:repository) { create :repository, created_by: user }

    it 'calls create activity for copying inventory' do
      expect(Activities::CreateActivityService)
        .to(receive(:call).with(hash_including(activity_type: :copy_inventory)))

      repository.copy(user, 'name for copied repo')
    end

    it 'adds activity in DB' do
      expect { repository.copy(user, 'name for copied repo') }
        .to(change { Activity.count })
    end
  end

  describe '.within_global_limits?' do
    let(:user) { create :user }

    context 'when have an archived repository' do
      before do
        Rails.configuration.x.global_repositories_limit = 2
        create :repository, created_by: user
        create :repository, :archived, created_by: user
      end

      after do
        Rails.configuration.x.global_repositories_limit = 0
      end

      it 'includes archived repositories in condition and returns false' do
        expect(described_class.within_global_limits?).to be_falsey
      end
    end
  end

  describe '.within_team_limits?' do
    let(:user) { create :user }

    context 'when have an archived repository' do
      before do
        Rails.configuration.x.team_repositories_limit = 2
        create :repository, team: team, created_by: user
        create :repository, :archived, team: team, created_by: user
      end

      after do
        Rails.configuration.x.team_repositories_limit = 0
      end

      let(:team) { create :team, created_by: user }

      it 'includes archived repositories in condition and returns false' do
        expect(described_class.within_team_limits?(team)).to be_falsey
      end
    end
  end
end
