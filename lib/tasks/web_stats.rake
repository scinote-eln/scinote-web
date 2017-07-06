namespace :web_stats do

  desc "Report login statistics from the application"
  task :login => :environment do
    def print_splitter
      puts "+--------------------------------------+-----------------+-----------------------+"
    end

    def print_header
      print_splitter
      puts "| Username                             | Times signed in | Last signed in on     |"
      print_splitter
    end

    def print_line(user)
      last_signed_in = "never"
      if user.last_sign_in_at.present?
        last_signed_in = I18n.l(user.last_sign_in_at, format: :full)
      end
      puts "| #{user.email.ljust(36)} " \
           "| #{user.sign_in_count.to_s.ljust(15)} " \
           "| #{last_signed_in.ljust(21)} |"
    end

    # Actual task code
    print_header
    User.all.each{ |u| print_line(u) }
    print_splitter

    # Calculate total & avg
    total = 0
    User.all.each{ |u| total += u.sign_in_count }
    avg = total.to_f / User.count.to_f

    puts "  Total times signed in: #{total}     Avg. times signed in: #{avg.round(4)}"
    puts ""
  end

  desc "Report information on last login"
  task :last_login => :environment do
    ll_user = User.where.not(current_sign_in_at: nil).order(current_sign_in_at: :desc).first
    ll_user2 = User.where.not(last_sign_in_at: nil).order(last_sign_in_at: :desc).first

    ll = ll_user.present? ? ll_user.current_sign_in_at : nil
    ll2 = ll_user2.present? ? ll_user2.last_sign_in_at : nil
    if ll.present? and ll2.present?
      ll_real = ll > ll2 ? ll : ll2
    elsif ll.present?
      ll_real = ll
    elsif ll2.present
      ll_real = ll2
    else
      ll_real = nil
    end

    puts "Current time: #{Time.now.to_s}"
    if ll_real.present?
      diff = ((Time.now - ll_real) / 1.hour).round
      puts "Last login at: #{ll_real.to_s}"
      puts "  (#{diff} hours ago)"
    else
      puts "Woops, seems nobody has logged in yet!"
    end
  end
end
