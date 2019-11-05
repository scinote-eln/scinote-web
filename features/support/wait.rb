# wait_for_ajax implementation for axios library
# def wait_for_ajax
#   counter = 0
#   while page.evaluate_script('window.IN_REQUEST')
#     counter += 1
#     sleep(0.1)
#     if (0.1 * counter) >= Capybara.default_max_wait_time
#       raise "AJAX request took longer than " \
#             "#{Capybara.default_max_wait_time} seconds."
#     end
#   end
# end

#  Jquery implementation
def wait_for_ajax
  Timeout.timeout(Capybara.default_max_wait_time) do
    loop until page.evaluate_script('jQuery.active').zero?
  end
end
