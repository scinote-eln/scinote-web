namespace :metrics do
  desc 'Prints out some basic decoupling metrics'
  task decoupling: :environment do
    erb_nr = 0
    jsx_nr = 0
    Dir.glob('**/*.erb') { erb_nr += 1 }
    Dir.glob('**/*.jsx') { jsx_nr += 1 }

    # Print the metrics
    puts ''
    puts '**********************************'
    puts '**                              **'
    puts '**     Decoupling metrics       **'
    puts '**                              **'
    puts '**********************************'
    puts ''
    puts 'Nr. of ERB template files (*.erb):'
    puts erb_nr
    puts ''
    puts 'Nr. of React template files (*.jsx):'
    puts jsx_nr
    puts ''
    puts '**********************************'
    puts ''
  end
end
