# frozen_string_literal: true

require 'rails_helper'

describe Team, type: :model do
  let(:team) { build :team }

  it 'is valid' do
    expect(team).to be_valid
  end

  it 'should be of class Team' do
    expect(subject.class).to eq Team
  end

  describe 'Database table' do
    it { should have_db_column :name }
    it { should have_db_column :created_at }
    it { should have_db_column :updated_at }
    it { should have_db_column :created_by_id }
    it { should have_db_column :last_modified_by_id }
    it { should have_db_column :description }
    it { should have_db_column :space_taken }
    it { should have_db_column :shareable_links_enabled }
  end

  describe 'Relations' do
    it { should belong_to(:created_by).class_name('User').optional }
    it { should belong_to(:last_modified_by).class_name('User').optional }
    it { should have_many :users }
    it { should have_many :projects }
    it { should have_many :protocols }
    it { should have_many :protocol_keywords }
    it { should have_many :tiny_mce_assets }
    it { should have_many :repositories }
    it { should have_many :reports }
    it { should have_many(:team_shared_objects).dependent(:destroy) }
    it { should have_many :shared_repositories }
    it { should have_many(:shareable_links).dependent(:destroy) }
  end

  describe 'Validations' do
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

  describe 'Callbacks' do
    it 'does not triggers destroy_all on shareable_links before save when shareable_links_enabled? is false' do
      allow(team).to receive(:shareable_links_enabled?).and_return(true)
      expect(team.shareable_links).not_to receive(:destroy_all)
      team.save
    end

    context 'when shareable_links_enabled is true' do
      it 'does not destroy shareable_links before saving' do
        team.shareable_links_enabled = true
        create_list(:shareable_link, 3, team: team)
        team.save

        expect(team.shareable_links.count).to eq(3)
      end
    end

    context 'when shareable_links_enabled is false' do
      it 'triggers destroy_all on shareable_links before save when shareable_links_enabled? is false' do
        allow(team).to receive(:shareable_links_enabled?).and_return(false)
        expect(team.shareable_links).to receive(:destroy_all)
        team.save
      end

      it 'destroys all shareable_links before saving' do
        team.shareable_links_enabled = true
        create_list(:shareable_link, 3, team: team)
        team.save
        team.shareable_links_enabled = false
        create_list(:shareable_link, 3, team: team)

        team.save

        expect(team.shareable_links.count).to eq(0)
      end
    end
  end
end
