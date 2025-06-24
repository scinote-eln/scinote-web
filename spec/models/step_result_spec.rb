# frozen_string_literal: true

require 'rails_helper'

describe StepResult, type: :model do
  let(:step_result) { build :step_result }

  it 'is valid' do
    expect(step_result).to be_valid
  end

  it 'should be of class form field value' do
    expect(subject.class).to eq StepResult
  end

  describe 'Database table' do
    it { should have_db_column :created_at }
    it { should have_db_column :updated_at }
  end

  describe 'Relations' do
    it { should belong_to(:step) }
    it { should belong_to(:result) }
    it { should belong_to(:created_by).class_name('User') }
  end
end
