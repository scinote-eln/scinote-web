# frozen_string_literal: true

require 'rails_helper'

describe Protocol, type: :model do
  let(:protocol) { build :protocol }

  it 'is valid' do
    expect(protocol).to be_valid
  end

  it 'should be of class Protocol' do
    expect(subject.class).to eq Protocol
  end

  describe 'Database table' do
    it { should have_db_column :name }
    it { should have_db_column :authors }
    it { should have_db_column :description }
    it { should have_db_column :added_by_id }
    it { should have_db_column :my_module_id }
    it { should have_db_column :team_id }
    it { should have_db_column :protocol_type }
    it { should have_db_column :parent_id }
    it { should have_db_column :parent_updated_at }
    it { should have_db_column :archived_by_id }
    it { should have_db_column :archived_on }
    it { should have_db_column :restored_by_id }
    it { should have_db_column :restored_on }
    it { should have_db_column :created_at }
    it { should have_db_column :updated_at }
    it { should have_db_column :published_on }
    it { should have_db_column :nr_of_linked_children }
  end

  describe 'Relations' do
    it { should belong_to(:team) }
    it { should belong_to(:added_by).class_name('User').optional }
    it { should belong_to(:parent).class_name('Protocol').optional }
    it { should belong_to(:archived_by).class_name('User').optional }
    it { should belong_to(:restored_by).class_name('User').optional }
    it { should have_many(:linked_children).class_name('Protocol') }
    it { should have_many :protocol_protocol_keywords }
    it { should have_many :protocol_keywords }
    it { should have_many :steps }
  end

  describe 'Validations' do
    it { should validate_presence_of :team }
    it { should validate_presence_of :protocol_type }
    it do
      should validate_length_of(:name).is_at_most(Constants::NAME_MAX_LENGTH)
    end
    it do
      should validate_length_of(:description)
        .is_at_most(Constants::RICH_TEXT_MAX_LENGTH)
    end
  end

  describe '.archive(user)' do
    let(:user) { create :user }
    let(:team) { create :team, created_by: user }
    let(:protocol) { create :protocol, :in_public_repository, team: team, added_by: user }

    it 'calls create activity for archiving protocol' do
      expect(Activities::CreateActivityService)
        .to(receive(:call)
              .with(hash_including(activity_type:
                                     :archive_protocol_in_repository)))

      protocol.archive user
    end

    it 'creats one new activity DB' do
      expect { protocol.archive(user) }.to change { Activity.count }.by(1)
    end
  end

  describe '.restore(user)' do
    let(:user) { create :user }
    let(:team) { create :team, created_by: user }
    let(:protocol) { create :protocol, :in_public_repository, team: team, added_by: user }

    it 'calls create activity for restoring protocol' do
      expect(Activities::CreateActivityService)
        .to(receive(:call)
              .with(hash_including(activity_type:
                                     :restore_protocol_in_repository)))

      protocol.restore user
    end

    it 'creats one new activity DB' do
      expect { protocol.restore(user) }.to change { Activity.count }.by(1)
    end
  end

  describe '.deep_clone_repository' do
    let(:user) { create :user }
    let(:team) { create :team, created_by: user }
    let(:protocol) { create :protocol, :in_public_repository, team: team, added_by: user }

    it 'calls create activity for protocol copy to repository' do
      expect(Activities::CreateActivityService)
        .to(receive(:call)
              .with(hash_including(activity_type:
                                     :copy_protocol_in_repository)))
      protocol.deep_clone_repository(user)
    end

    it 'creats one new activity DB' do
      expect { protocol.deep_clone_repository(user) }.to change { Activity.count }.by(1)
    end
  end
end
