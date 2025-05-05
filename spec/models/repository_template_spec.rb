# frozen_string_literal: true

require 'rails_helper'

describe RepositoryTemplate, type: :model do
  let(:repository_template) { build :repository_template }

  it 'is valid' do
    expect(repository_template).to be_valid
  end

  it 'should be of class Repository Template' do
    expect(subject.class).to eq RepositoryTemplate
  end

  describe 'Database table' do
    it { should have_db_column :name }
    it { should have_db_column :team_id }
    it { should have_db_column :column_definitions }
    it { should have_db_column :predefined }
    it { should have_db_column :created_at }
    it { should have_db_column :updated_at }
  end

  describe 'Relations' do
    it { should belong_to :team }
    it { should have_many(:repositories).dependent(:nullify) }
  end
end
