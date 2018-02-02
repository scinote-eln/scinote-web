require 'rails_helper'

describe Settings, type: :model do
  it 'should be of class Settings' do
    expect(subject.class).to eq Settings
  end

  describe 'Database table' do
    it { should have_db_column :type }
    it { should have_db_column :values }
  end
end
