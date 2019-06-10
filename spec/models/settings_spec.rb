# frozen_string_literal: true

require 'rails_helper'

describe Settings, type: :model do
  let(:settings) { build :settings }

  it 'is valid' do
    expect(settings).to be_valid
  end

  it 'should be of class Settings' do
    expect(subject.class).to eq Settings
  end

  describe 'Database table' do
    it { should have_db_column :type }
    it { should have_db_column :values }
  end
end
