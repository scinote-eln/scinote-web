require 'rails_helper'

describe SampleGroup, type: :model do
  it 'should be of class SampleGroup' do
    expect(subject.class).to eq SampleGroup
  end

  describe 'Database table' do
    it { should have_db_column :name }
    it { should have_db_column :color }
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
      table = SampleGroup.reflect_on_association(:samples)
      expect(table.macro).to eq(:has_many)
    end
  end

  describe 'Should be a valid object' do
    let!(:team_one) { create :team, name: 'My team' }
    it { should validate_presence_of :name }
    it { should validate_presence_of :color }
    it { should validate_presence_of :team }
    it do
      should validate_length_of(:name).is_at_most(Constants::NAME_MAX_LENGTH)
    end
    it do
      should validate_length_of(:color).is_at_most(Constants::COLOR_MAX_LENGTH)
    end
    it 'should have uniq name scoped to team' do
      create :sample_group, name: 'My Group', team: team_one
      new_group = build :sample_group, name: 'My Group', team: team_one
      expect(new_group).to_not be_valid
    end
  end
end
