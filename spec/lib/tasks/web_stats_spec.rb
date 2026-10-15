# frozen_string_literal: true

require 'rails_helper'

describe 'web_stats:login' do
  include_context 'rake once'

  it 'lists users with sign in counts and totals' do
    User.update_all(sign_in_count: 0, last_sign_in_at: nil)
    create(:user, email: 'web.stats.a@example.com', sign_in_count: 4, last_sign_in_at: Time.utc(2024, 1, 2, 3, 4))
    create(:user, email: 'web.stats.b@example.com', sign_in_count: 2, last_sign_in_at: nil)
    total = User.sum(:sign_in_count)
    avg = (total.to_f / User.count).round(4)

    expect { subject.invoke }.to output(
      a_string_matching(/^\| web\.stats\.a@example\.com\s+\| 4\s+\| \S.*\|$/)
      .and(match(/^\| web\.stats\.b@example\.com\s+\| 2\s+\| never\s+\|$/))
      .and(match(/Total times signed in: #{total}\s+Avg\. times signed in: #{avg}/))
      .and(match(/^\+-+\+-+\+-+\+$/))
    ).to_stdout
  end
end

describe 'web_stats:last_login' do
  include_context 'rake once'

  before { User.update_all(current_sign_in_at: nil, last_sign_in_at: nil) }

  it 'says nobody logged in when there are no sign ins' do
    # bug: `ll2.present` (missing `?`) raises NoMethodError when nobody has signed in either
    pending 'bug: lib/tasks/web_stats.rake `ll2.present` without question mark raises NoMethodError'
    expect { subject.invoke }.to output(/Current time: .*Woops, seems nobody has logged in yet!/m).to_stdout
  end

  it 'reports the newest of current and last sign in' do
    create(:user, current_sign_in_at: 3.hours.ago, last_sign_in_at: 10.hours.ago)
    create(:user, current_sign_in_at: nil, last_sign_in_at: 5.hours.ago)
    newest = User.maximum(:current_sign_in_at)

    expect { subject.invoke }.to output(/Last login at: #{Regexp.escape(newest.to_s)}\n  \(3 hours ago\)/).to_stdout
  end

  it 'uses the last sign in when it is newer than the current one' do
    create(:user, current_sign_in_at: 8.hours.ago, last_sign_in_at: 2.hours.ago)

    expect { subject.invoke }.to output(/\(2 hours ago\)/).to_stdout
  end

  it 'reports a login when only last_sign_in_at is set' do
    create(:user, current_sign_in_at: nil, last_sign_in_at: 6.hours.ago)

    # bug: `ll2.present` (missing `?`) raises NoMethodError
    pending 'bug: lib/tasks/web_stats.rake `ll2.present` without question mark raises NoMethodError'
    expect { subject.invoke }.to output(/\(6 hours ago\)/).to_stdout
  end
end
