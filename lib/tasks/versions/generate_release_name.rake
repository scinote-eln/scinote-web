namespace :versions do
  desc 'Generate a new release name'
  task generate_release_name: :environment do
    def rand_el(arr)
      arr[rand(arr.count)]
    end

    # Load the data from JSON
    adjectives = JSON.parse(File.read('lib/tasks/versions/adjectives.json'))
    scientists = JSON.parse(File.read('lib/tasks/versions/scientists.json'))

    puts '------------------------------------'
    puts ''
    puts 'SciNote release name generator v0.1 ALPHA'
    puts ''
    puts '------------------------------------'

    puts ''
    puts 'Choose what you would like to do:'
    puts '1) Provide a scientist by yourself'
    puts '2) Randomly choose a scientist from a pre-defined list'
    res = $stdin.gets.strip
    unless res.in?(['', '1', '2'])
      puts 'Invalid parameter, exiting'
      next
    end

    # First, pick scientist name
    if res.in?(['', '1'])
      puts 'Enter full scientist first name (all but surname) ' \
           'in capitalized case'
      first_name = $stdin.gets.strip
      puts 'Enter full scientist surname ' \
           'in capitalized case'
      last_name = $stdin.gets.strip
      key = last_name[0].downcase.to_sym
      full_name = "#{first_name} #{last_name}"
    else
      key = rand_el(scientists.keys)
      full_name = rand_el(scientists[key])
      last_name = full_name.split(' ')[-1]
      puts "Randomly chosen scientist: #{full_name}"
      puts ''
    end

    # Now, pick adjective
    adjective = rand_el(adjectives[key])

    puts '------------------------------------'
    puts 'Tadaaaa!'
    puts 'The new release will be named......'
    puts '(waaaaait for iiiiit)'
    puts ''
    puts '##############################################'
    puts " #{adjective.capitalize} #{last_name}"
    puts " (full name: #{full_name})"
    puts '##############################################'

    loop do
      puts ''
      puts 'What would you like to do?'
      puts '(E) Exit'
      puts '(a) generate new adjective'
      puts '(s) generate new random scientist'
      res = $stdin.gets.strip
      unless res.in?(['', 'e', 'E', 'a', 'A', 's', 'S'])
        puts 'Invalid parameter!'
        next
      end

      break if res.in?(['', 'e', 'E'])

      if res.in?(%w(s S))
        key = rand_el(scientists.keys)
        full_name = rand_el(scientists[key])
        last_name = full_name.split(' ')[-1]
      end

      adjective = rand_el(adjectives[key])

      puts ''
      puts '##############################################'
      puts " #{adjective.capitalize} #{last_name} "
      puts " (full name: #{full_name})"
      puts '##############################################'
    end
  end
end
