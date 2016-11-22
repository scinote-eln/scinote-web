namespace :sign_up_constraint do
  desc 'Adds email domain constraint to the users table. '\
        'E.g: scinote.net'
  task :email_domain, [:domain] => :environment do |_, args|
    if args.blank? ||
       args.empty? ||
       args[:domain].blank?
      puts 'Please add the email domain'
      return
    end

    domain = args[:domain]
    domain = domain.strip.gsub(/\./, '\\.')

    ActiveRecord::Base.connection.execute(
      "ALTER TABLE " \
         "users " \
      "DROP CONSTRAINT IF EXISTS email_must_be_company_email, " \
      "ADD CONSTRAINT " \
        "email_must_be_company_email " \
      "CHECK ( email ~* '^[A-Za-z0-9._%-]+@#{domain}' ) " \
      "not valid;"
    )
    puts "Created the following domain constraint: #{args[:domain]}"
  end

  desc 'Remove email domain constraint from the users table.'
  task remove_domain: :environment do
    ActiveRecord::Base.connection.execute(
      'ALTER TABLE ' \
         'users ' \
      'DROP CONSTRAINT IF EXISTS email_must_be_company_email; '
    )
    puts 'Email constraint has been removed'
  end
end
