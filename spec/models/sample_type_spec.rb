require 'rails_helper'

describe SampleType, type: :model do
  it 'should be of class SampleType' do
    expect(subject.class).to eq SampleType
  end

  describe 'Database table' do
    it { should have_db_column :name }
    it { should have_db_column :team_id }
    it { should have_db_column :created_at }
    it { should have_db_column :updated_at }
    it { should have_db_column :created_by_id }
    it { should have_db_column :last_modified_by_id }
  end

  describe 'Relations' do
    it { should belong_to :team }
    it { should belong_to(:created_by).class_name('User') }
    it { should belong_to(:last_modified_by).class_name('User') }

    it 'have many samples' do
      table = SampleType.reflect_on_association(:samples)
      expect(table.macro).to eq(:has_many)
    end
  end

  describe 'Should be a valid object' do
    let(:team) { create :team }

    it { should validate_presence_of :name }
    it { should validate_presence_of :team }
    it do
      should validate_length_of(:name).is_at_most(Constants::NAME_MAX_LENGTH)
    end

    it 'should have uniq name scoped to team' do
      create :sample_type, name: 'Sample one', team: team
      new_type = build :sample_type, name: 'Sample one', team: team
      expect(new_type).to_not be_valid
    end

    it 'should not be case sensitive' do
      create :sample_type, name: 'Sample T', team: team
      new_type = build :sample_type, name: 'SAMPLE T', team: team
      expect(new_type).to_not be_valid
    end
  end
end
