# frozen_string_literal: true

require 'rails_helper'

describe WopiAction, type: :model do
  let(:wopi_action) { build :wopi_action }

  it 'is valid' do
    expect(wopi_action).to be_valid
  end

  it 'should be of class WopiAction' do
    expect(subject.class).to eq WopiAction
  end

  describe 'Database table' do
    it { should have_db_column :action }
    it { should have_db_column :extension }
    it { should have_db_column :urlsrc }
    it { should have_db_column :wopi_app_id }
  end

  describe 'Relations' do
    it { should belong_to(:wopi_app) }
  end

  describe 'Validations' do
    it { should validate_presence_of :action }
    it { should validate_presence_of :extension }
    it { should validate_presence_of :urlsrc }
    it { should validate_presence_of :wopi_app }
  end
end
