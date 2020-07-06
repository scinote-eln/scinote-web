# frozen_string_literal: true

### Notes
# Only CSS selector is working, Jquery is not working
# e.g.: buttons = all("a.btn:contains(#{text}),input.btn[value=#{text}]")
# Change wait time to 0, otherwise waiting default time (30s) to get empty array of elements


### Improvments
# Threads? When first is successful, kill others?
# NOT WOKRING: first(".btn:nth(#{position-1})", text: text)
# Wait time could be problem. Find&First is witing until first element appear, but all is waiting until max wait
# time, what is 30s by default. This is why override with 1 second.

def check_active_team(team)
  expect(page).to have_selector '#team-switch button', text: team
end

def sci_click_on_button(text:, position: 1)
  raise 'Position cannot be lower than 1' if position < 1

  if position == 1
    btn = first('.btn', text: text)
  else
    btn = all('.btn', text: text, wait: 1)[position-1]
  end
  btn.click
end

def sci_click_on_icon(icon_class:, position: 1, container: nil)
  raise 'Position cannot be lower than 1' if position < 1

  scope = container ? find(container) : page

  if position == 1
    icon = scope.first(".fas.#{icon_class}")
  else
    icon = scope.all(".fas.#{icon_class}")[position-1]
  end

  icon.click
end
