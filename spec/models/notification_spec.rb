require 'rails_helper'

describe Notification, type: :model do
  it 'should be of class Notification' do
    expect(subject.class).to eq Notification
  end

  describe 'Database table' do
    it { should have_db_column :id }
    it { should have_db_column :title }
    it { should have_db_column :message }
    it { should have_db_column :type_of }
    it { should have_db_column :generator_user_id }
    it { should have_db_column :created_at }
    it { should have_db_column :updated_at }
  end

  describe 'Relations' do
    it { should belong_to(:generator_user).class_name('User') }
    it { should have_many :users }
    it { should have_many :user_notifications }
  end
end
