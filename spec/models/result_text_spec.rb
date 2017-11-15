require 'rails_helper'

describe ResultText, type: :model do
  it 'should be of class ResultText' do
    expect(subject.class).to eq ResultText
  end

  describe 'Database table' do
    it { should have_db_column :result_id }
    it { should have_db_column :text }
  end

  describe 'Relations' do
    it { should belong_to :result }
    it { should have_many :tiny_mce_assets }
  end

  describe 'Should be a valid object' do
    it { should validate_presence_of :text }
    it { should validate_presence_of :result }
    it do
      should validate_length_of(:text)
               .is_at_most(Constants::RICH_TEXT_MAX_LENGTH)
    end
  end
end
