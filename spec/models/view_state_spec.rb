# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ViewState, type: :model do
  let(:view_state) { build :view_state, :team }

  it 'is valid' do
    expect(view_state).to be_valid
  end

  it 'should be of class ViewState' do
    expect(subject.class).to eq ViewState
  end

  describe 'Database table' do
    it { should have_db_column :state }
    it { should have_db_column :user_id }
    it { should have_db_column :viewable_type }
    it { should have_db_column :viewable_id }
    it { should have_db_column :created_at }
    it { should have_db_column :updated_at }
  end

  describe 'Relations' do
    it { should belong_to :user }
    it { should belong_to :viewable }
  end
end
