# frozen_string_literal: true

require 'rails_helper'

describe Settings, type: :model do
  let(:settings) { build(:settings) }
  let(:application_settings) { build(:settings, :with_load_values_from_env_defined) }

  it 'raises not NotImplementedError' do
    expect { settings.load_values_from_env }.to raise_error(NotImplementedError)
  end


  it 'is valid' do
    expect(application_settings).to be_valid
  end

  it 'should be of class Settings' do
    expect(application_settings.class).to eq Settings
  end

  describe 'Database table' do
    it { should have_db_column :type }
    it { should have_db_column :values }
  end
end
