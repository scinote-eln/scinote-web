# frozen_string_literal: true

require 'rails_helper'

describe RepositoryStatusValue do
  let(:repository_status_value) { build :repository_status_value }

  it 'is valid' do
    expect(repository_status_value).to be_valid
  end

  describe 'Validations' do
    describe '#repository_status_item' do
      it { is_expected.to validate_presence_of(:repository_status_item) }
    end
  end

  describe 'Associations' do
    it { is_expected.to belong_to(:repository_status_item) }
    it { is_expected.to belong_to(:created_by).optional }
    it { is_expected.to belong_to(:last_modified_by).optional }
  end
end
