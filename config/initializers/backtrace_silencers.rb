# Be sure to restart your server when you modify this file.

# You can add backtrace silencers for libraries that you're using but don't wish to see in your backtraces.
# Rails.backtrace_cleaner.add_silencer { |line| line =~ /my_noisy_library/ }

# Silence the WOPI method override to prevent "trapping" of stack/backtrace
# See https://stackoverflow.com/questions/29498145
Rails.backtrace_cleaner.add_silencer do |line|
  line =~ %r{app/middlewares/wopi_method_override}
end

# You can also remove all the silencers if you're trying to debug a problem that might stem from framework code.
# Rails.backtrace_cleaner.remove_silencers!
