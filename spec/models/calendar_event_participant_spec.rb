# frozen_string_literal: true

require 'rails_helper'

describe CalendarEventParticipant, type: :model do
  let(:calendar_event_participant) { build :calendar_event_participant }

  it 'is valid' do
    expect(calendar_event_participant).to be_valid
  end

  it 'should be of class CalendarEventParticipant' do
    expect(subject.class).to eq CalendarEventParticipant
  end

  describe 'Database table' do
    it { should have_db_column :user_id }
    it { should have_db_column :calendar_event_id }
    it { should have_db_column :created_at }
    it { should have_db_column :updated_at }
  end

  describe 'Relations' do
    it { should belong_to(:user) }
    it { should belong_to(:calendar_event) }
  end

   describe 'Validations' do
    it {
      expect(calendar_event_participant).to validate_uniqueness_of(:user_id)
        .scoped_to(:calendar_event_id)
    }
  end
end
