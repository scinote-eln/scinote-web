namespace :sign_up_constraint do
  desc 'Adds email domain constraint to the users table. '\
        'E.g: scinote.net'
  task :email_domain, [:domain] => :environment do |_, args|
    if args.blank? || args[:domain].blank?
      puts 'Please add the email domain'
      return
    end

    domain = args[:domain]
    domain = domain.strip.gsub(/\./, '\\.')

    ActiveRecord::Migration.add_check_constraint(
      :users,
      "email ~* '^[A-Za-z0-9._%-+]+@#{domain}'",
      name: 'email_must_be_company_email',
      validate: false
    )
    puts "Created the following domain constraint: #{args[:domain]}"
  end

  desc 'Remove email domain constraint from the users table.'
  task remove_domain: :environment do
    ActiveRecord::Migration.remove_check_constraint :users, name: 'email_must_be_company_email'
    puts 'Email constraint has been removed'
  end
end
