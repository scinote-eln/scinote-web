# frozen_string_literal: true

### Notes
# Only CSS selector is working, Jquery is not working
# e.g.: buttons = all("a.btn:contains(#{text}),input.btn[value=#{text}]")
# Change wait time to 0, otherwise waiting default time (30s) to get empty array of elements


### Improvments
# Threads? When first is successful, kill others?

def check_active_team(team)
  expect(page).to have_selector '#team-switch button', text: team
end

def sci_click_on_button(text:, position: 1)
  # default wait 1 second for now...
  raise 'Position cannot be lower than 1' if position < 1

  # Find method is faster, so try with find, if nothing found, go with all
  # Use wait only for all, otherwise testsuit will wait on first Find if button is an form submit
  if position == 1
    # begin
      btn = first('.btn', text: text)
    # rescue Capybara::ElementNotFound # We assume and hope button is an input, so try to find input
    #   btn = first("input.btn[value=#{text}]", wait: wait)
    # end
  else
    raise "Not Implemented"

    # buttons = all('.btn', text: text, wait: wait)

    # unless buttons.any? # Maybe .btn is an input field, and does not have text, check for value
    #   buttons = all("input.btn[value=#{text}]", wait: wait)
    # end

    # btn = buttons[position - 1]
    btn = first(".btn:nth(#{position-1})", text: text)
  end

  btn.click
end

def sci_click_on_icon(icon_class:, position: 1, wait: 1)
  if position == 1
    icon = first(".fas.#{icon_class}", wait: wait)
    # Fallback here in icon is not in a and span... ?
  else
    raise "Not Implemented"
    # icon = all("a>span.#{icon_class}:not(.hidden-lg)", wait: wait)[position-1]
    icon = first(".fas.#{icon_class}:nth-child(#{position-1}n)", wait: wait)
  end

  icon.click
end
