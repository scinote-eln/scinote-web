require 'rails_helper'

describe ShareableLink, type: :model do
  let(:shareable_link) { build :shareable_link }

  it 'is valid' do
    expect(shareable_link).to be_valid
  end

  it 'should be of class ShareableLink' do
    expect(subject.class).to eq ShareableLink
  end

  describe 'Database table' do
    it { should have_db_column :uuid }
    it { should have_db_column :created_at }
    it { should have_db_column :updated_at }
    it { should have_db_column :created_by_id }
    it { should have_db_column :last_modified_by_id }
    it { should have_db_column :description }
    it { should have_db_column :team_id }
    it { should have_db_column :shareable_type }
    it { should have_db_column :shareable_id }
  end

  describe 'Relations' do
    it { should belong_to(:shareable) }
    it { should belong_to(:team) }
    it { should belong_to(:created_by).class_name('User') }
    it { should belong_to(:last_modified_by).class_name('User').optional }
  end

  describe 'Validations' do
    it { should validate_length_of(:description).is_at_most(Constants::RICH_TEXT_MAX_LENGTH) }

    it 'validates uniqueness of shareable_type scoped to shareable_id' do
      shareable_link1 = create(:shareable_link)
      shareable_link2 = build(:shareable_link,
                              shareable_type: shareable_link1.shareable_type,
                              shareable_id: shareable_link1.shareable_id)

      expect(shareable_link2).not_to be_valid
      expect(shareable_link2.errors[:shareable_type]).to include('has already been taken')
    end
  end
end
