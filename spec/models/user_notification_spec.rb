require 'rails_helper'

describe UserNotification, type: :model do
  it 'should be of class UserNotification' do
    expect(subject.class).to eq UserNotification
  end

  describe 'Database table' do
    it { should have_db_column :user_id }
    it { should have_db_column :notification_id }
    it { should have_db_column :checked }
    it { should have_db_column :created_at }
    it { should have_db_column :updated_at }
  end

  describe 'Relations' do
    it { should belong_to :user }
    it { should belong_to :notification }
  end
end
