# frozen_string_literal: true

require 'rails_helper'

describe ActivityHelper, type: :helper do
  describe '#activity_truncate' do
    it 'returns a sanitized message unchanged when it has no strong titles' do
      expect(helper.activity_truncate('Plain <em>text</em> only')).to eq 'Plain <em>text</em> only'
    end

    it 'keeps a short strong title as it is' do
      result = helper.activity_truncate('Created <strong>short</strong>', 20)

      expect(result).to include '<strong>short</strong>'
      expect(result).not_to include 'modal-tooltip'
    end

    it 'truncates a long strong title and adds a tooltip with the full title' do
      long_title = 'abcdefghijklmnopqrstuvwxyz'
      result = helper.activity_truncate("Created <strong>#{long_title}</strong>", 10)

      expect(result).to include 'modal-tooltip'
      expect(result).to include 'abcdefg...'
      expect(result).to include 'modal-tooltiptext'
      expect(result).to include long_title
    end

    it 'removes script markup from the message through the sanitizer' do
      result = helper.activity_truncate('Edited <strong>name<script>alert(1)</script></strong>', 50)

      expect(result).to include 'Edited'
      expect(result).not_to include '<script>'
      expect(result).not_to include 'alert(1)'
    end

    it 'keeps a short smart annotation link whole' do
      result = helper.activity_truncate('Edited <strong><a href="/x"><span>Exp</span></a></strong>', 50)

      expect(result).to include '<a href="/x">'
      expect(result).to include 'Exp</span></a>'
      expect(result).not_to include 'modal-tooltip'
    end

    it 'counts the visible text of a smart annotation when it truncates the title' do
      title = 'Alpha experiment with a very long name'
      result = helper.activity_truncate(
        "Created <strong><a href=\"/x\"><span>#{title}</span></a> tail</strong>", 20
      )

      expect(result).to include 'modal-tooltip'
      expect(result).to include 'modal-tooltiptext'
      expect(result).to include '<a href="/x">'
      expect(result).to include title
    end

    it 'walks through several smart annotations in one title' do
      result = helper.activity_truncate(
        'Moved <strong><a href="/x"><span>Alpha</span></a> and <a href="/y"><span>Beta</span></a> rest</strong>', 20
      )

      expect(result).to include '<a href="/x">'
      expect(result).to include '<a href="/y">'
      expect(result).to include 'Alpha'
      expect(result).to include 'Beta'
    end
  end

  describe '#days_since_1970' do
    it 'returns the number of whole days since the epoch' do
      expect(helper.days_since_1970(Time.at((5 * 86_400) + 100))).to eq 5
    end

    it 'returns 0 for the epoch itself' do
      expect(helper.days_since_1970(Time.at(0))).to eq 0
    end
  end

  describe '#calculate_previous_date' do
    let(:first_activity) { double('Activity', created_at: Time.zone.parse('2026-03-10 12:00')) }
    let(:previous_batch_date) { Date.new(2026, 1, 5) }

    it 'returns the date of the first activity for the second index on the first page' do
      activities = double('Activities', first_page?: true)
      allow(activities).to receive(:[]).with(0).and_return(first_activity)

      expect(helper.calculate_previous_date(activities, 1, previous_batch_date)).to eq Date.new(2026, 3, 10)
    end

    it 'returns the batch date for the second index when not on the first page' do
      activities = double('Activities', first_page?: false)

      expect(helper.calculate_previous_date(activities, 1, previous_batch_date)).to eq previous_batch_date
    end

    it 'returns the created date of the previous activity for other indexes' do
      previous = double('Activity', created_at: Time.zone.parse('2026-02-01 08:30'))
      activities = double('Activities', first_page?: true)
      allow(activities).to receive(:[]).with(1).and_return(previous)

      expect(helper.calculate_previous_date(activities, 2, previous_batch_date)).to eq Date.new(2026, 2, 1)
    end

    it 'falls back to 1901-01-01 when there is no previous activity' do
      activities = double('Activities', first_page?: true)
      allow(activities).to receive(:[]).with(2).and_return(nil)

      expect(helper.calculate_previous_date(activities, 3, previous_batch_date)).to eq Date.new(1901, 1, 1)
    end
  end
end
