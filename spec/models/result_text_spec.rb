# frozen_string_literal: true

require 'rails_helper'

describe ResultText, type: :model do
  let(:result_text) { build :result_text }

  it 'is valid' do
    expect(result_text).to be_valid
  end

  it 'should be of class ResultText' do
    expect(subject.class).to eq ResultText
  end

  describe 'Database table' do
    it { should have_db_column :result_id }
    it { should have_db_column :text }
  end

  describe 'Relations' do
    it { should belong_to :result }
    it { should have_many :tiny_mce_assets }
  end

  describe 'Validations' do
    describe '#text' do
      it { is_expected.to validate_presence_of :text }
      it { is_expected.to validate_length_of(:text).is_at_most(Constants::RICH_TEXT_MAX_LENGTH) }
    end

    describe '#result' do
      it { is_expected.to validate_presence_of :result }
    end
  end
end
