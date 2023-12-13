# frozen_string_literal: true

require 'rails_helper'

describe Notification, type: :model do
  let(:notification) { build :notification }

  it 'is valid' do
    expect(notification).to be_valid
  end

  it 'should be of class Notification' do
    expect(subject.class).to eq Notification
  end

  describe 'Database table' do
    it { should have_db_column :id }
    it { should have_db_column :created_at }
    it { should have_db_column :updated_at }
  end

  describe 'Relations' do
    it { should belong_to(:recipient) }
  end
end
