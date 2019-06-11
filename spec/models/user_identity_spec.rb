# frozen_string_literal: true

require 'rails_helper'

describe UserIdentity, type: :model do
  let(:user_identity) { build :user_identity }

  it 'is valid' do
    expect(user_identity).to be_valid
  end

  it 'should be of class UserIdentity' do
    expect(subject.class).to eq UserIdentity
  end

  describe 'Relations' do
    it { is_expected.to belong_to :user }
  end

  describe 'Validations' do
    describe '#uid' do
      it { is_expected.to validate_presence_of :uid }
      it { expect(user_identity).to validate_uniqueness_of(:uid).scoped_to(:provider) }
    end

    describe '#provider' do
      it { is_expected.to validate_presence_of :provider }
      it { expect(user_identity).to validate_uniqueness_of(:provider).scoped_to(:user_id) }
    end
  end
end
