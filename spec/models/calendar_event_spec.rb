# frozen_string_literal: true

require 'rails_helper'

describe CalendarEvent, type: :model do
  let(:calendar_event) { build :calendar_event }

  it 'is valid' do
    expect(calendar_event).to be_valid
  end

  it 'should be of class CalendarEvent' do
    expect(subject.class).to eq CalendarEvent
  end

  describe 'Database table' do
    it { should have_db_column :team_id }
    it { should have_db_column :created_at }
    it { should have_db_column :updated_at }
    it { should have_db_column :created_by_id }
    it { should have_db_column :metadata }
    it { should have_db_column :event_type }
    it { should have_db_column :end_at }
    it { should have_db_column :start_at }
    it { should have_db_column :subject_id }
    it { should have_db_column :subject_type }
  end

  describe 'Relations' do
    it { should belong_to(:created_by).class_name('User') }
    it { should belong_to(:team).class_name('Team') }
    it { should belong_to(:subject) }
    it { should have_many :calendar_event_participants }
    it { should have_many :users }
  end

  describe "polymorphic subject and connected destroys" do
    let(:repository_row) { create(:repository_row) }
    let(:user) { create(:user) }
    let(:team) { create(:team) }

    it "can belong to a RepositoryRow" do
      event = CalendarEvent.create!(subject: repository_row, team: team, created_by: user, event_type: Faker::Name.unique.name)

      expect(event.subject).to eq(repository_row)
      expect(event.subject_type).to eq("RepositoryRow")
    end

    it "destroys associated team" do
      event = CalendarEvent.create!(subject: repository_row, team: team, created_by: user, event_type: Faker::Name.unique.name)
      expect { team.destroy }.to change(CalendarEvent, :count).by(-1)
    end

     it "destroys associated subject" do
      event = CalendarEvent.create!(subject: repository_row, team: team, created_by: user, event_type: Faker::Name.unique.name)
      expect { repository_row.destroy }.to change(CalendarEvent, :count).by(-1)
    end
  end
end
