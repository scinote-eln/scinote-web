namespace :sign_up_constraint do
  desc 'Adds email domain constraint to the users table. '\
        'E.g: scinote.net'
  task :email_domain, [:domain] => :environment do |_, args|
    include DatabaseHelper

    if args.blank? ||
       args.empty? ||
       args[:domain].blank?
      puts 'Please add the email domain'
      return
    end

    domain = args[:domain]
    domain = domain.strip.gsub(/\./, '\\.')

    add_check_constraint(
      'users',
      'email_must_be_company_email',
      "email ~* '^[A-Za-z0-9._%-+]+@#{domain}'"
    )
    puts "Created the following domain constraint: #{args[:domain]}"
  end

  desc 'Remove email domain constraint from the users table.'
  task remove_domain: :environment do
    include DatabaseHelper

    drop_constraint('users', 'email_must_be_company_email')
    puts 'Email constraint has been removed'
  end
end
