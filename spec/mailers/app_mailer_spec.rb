# frozen_string_literal: true

require 'rails_helper'

describe AppMailer, type: :mailer do
  let(:user) { create :user, full_name: 'Mailer Tester' }
  let(:host) { Rails.application.config.action_mailer.default_url_options[:host] }

  def body_of(mail)
    mail.body.encoded
  end

  describe '#notification' do
    let(:notification_class) do
      Struct.new(:deliver, :type_of, :system_message, :title, :message, keyword_init: true) do
        def deliver?
          deliver
        end

        def system_message?
          system_message
        end
      end
    end
    let(:notification) do
      notification_class.new(deliver: false, type_of: 'assignment', system_message: false,
                             title: 'Task <a href="/projects/1">Alpha</a> assigned',
                             message: 'See <a href="/my_modules/2">the task</a>')
    end
    let(:mail) { described_class.notification(user.id, notification) }

    it 'is addressed to the user with the generic notification subject' do
      expect(mail.to).to eq [user.email]
      expect(mail.subject).to eq I18n.t('notifications.email_title')
    end

    it 'uses the data-ready subject for a deliver notification' do
      notification.deliver = true
      notification.message = 'plain'
      expect(described_class.notification(user.id, notification).subject)
        .to eq I18n.t('notifications.deliver.email_subject')
    end

    it 'lets opts override the headers' do
      mail = described_class.notification(user.id, notification, subject: 'Custom', to: 'other@example.com')
      expect(mail.subject).to eq 'Custom'
      expect(mail.to).to eq ['other@example.com']
    end

    it 'raises RecordNotFound for an unknown user' do
      expect { described_class.notification(User.maximum(:id).to_i + 1000, notification).message }
        .to raise_error(ActiveRecord::RecordNotFound)
    end

    it 'renders greeting, type, title and message with absolute links' do
      body = body_of(mail)
      expect(body).to include('Hello Mailer Tester')
      expect(body).to include(CGI.escapeHTML(I18n.t('notifications.email_title')))
      expect(body).to include("Type: #{I18n.t('notifications.types.assignment')}")
      expect(body).to include("href=\"http://#{host}/projects/1\"")
      expect(body).to include("href=\"http://#{host}/my_modules/2\"")
      expect(body).to include('Alpha')
    end

    it 'renders the title and message unescaped for system messages' do
      notification.system_message = true
      notification.type_of = 'system_message'
      notification.title = '<b>Maintenance</b>'
      notification.message = '<i>tonight</i>'
      body = body_of(described_class.notification(user.id, notification))
      expect(body).to include('<b>Maintenance</b>').and include('<i>tonight</i>')
      expect(body).to include("Type: #{I18n.t('notifications.types.system_message')}")
    end

    it 'renders the deliver text and an absolute zip export download link' do
      notification.deliver = true
      notification.title = 'ignored'
      notification.message = "<a data-id='42' href='/zip_exports/download/42'>Download</a>"
      body = body_of(described_class.notification(user.id, notification))
      expect(body).to include(I18n.t('notifications.deliver.email_body_1'))
      expect(body).to include(I18n.t('notifications.deliver.download_link'))
      expect(body).to include("href='http://#{host}/zip_exports/download/42'")
      expect(body).not_to include(CGI.escapeHTML(I18n.t('notifications.email_title')))
    end

    it 'uses the export-all download url for export-all zips' do
      notification.deliver = true
      notification.message = "<a data-id='7' href='/zip_exports/download_export_all_zip/7'>x</a>"
      body = body_of(described_class.notification(user.id, notification))
      expect(body).to include("http://#{host}/zip_exports/download_export_all_zip/7")
    end
  end

  describe '#general_notification' do
    let(:record) do
      Notification.create!(recipient: user, type: 'GeneralNotification', read_at: nil,
                           params: { title: 'Heads up', message: 'Open <a href="/projects/5">project</a>' })
    end
    let(:mail) { described_class.with(recipient: user, record: record).general_notification }

    it 'has recipient and subject' do
      expect(mail.to).to eq [user.email]
      expect(mail.subject).to eq I18n.t('notifications.email_title')
    end

    it 'renders name, title and message with absolute links' do
      body = body_of(mail)
      expect(body).to include('Hello Mailer Tester')
      expect(body).to include('Type: Heads up')
      expect(body).to include("href=\"http://#{host}/projects/5\"")
    end

    it 'lets opts override headers' do
      mail = described_class.with(recipient: user, record: record).general_notification(subject: 'Other')
      expect(mail.subject).to eq 'Other'
    end

    it 'is delivered by the GeneralNotification email delivery method' do
      expect(GeneralNotification.delivery_methods.find { |m| m[:name] == :email }[:options])
        .to include(mailer: 'AppMailer', method: :general_notification)
    end
  end

  describe 'Devise mails' do
    let(:token) { 'tok3n-abc' }

    it 'is the configured devise mailer' do
      expect(Devise.mailer).to eq described_class
    end

    it 'sends confirmation instructions with the token link' do
      mail = described_class.confirmation_instructions(user, token)
      expect(mail.to).to eq [user.email]
      expect(mail.from).to eq(ENV['MAIL_FROM'].present? ? [ENV['MAIL_FROM']] : nil)
      expect(mail.subject).to eq I18n.t('devise.mailer.confirmation_instructions.subject')
      body = body_of(mail)
      expect(body).to include("Welcome #{user.email}!")
      expect(body).to include("http://#{host}/users/confirmation?confirmation_token=#{token}")
    end

    it 'sends reset password instructions with the token link' do
      mail = described_class.reset_password_instructions(user, token)
      expect(mail.to).to eq [user.email]
      expect(mail.subject).to eq I18n.t('devise.mailer.reset_password_instructions.subject')
      body = body_of(mail)
      expect(body).to include("Hello #{user.email}!")
      expect(body).to include("reset_password_token=#{token}")
      expect(body).to include("http://#{host}/users/password/edit")
    end

    it 'sends unlock instructions with the token link' do
      mail = described_class.unlock_instructions(user, token)
      expect(mail.to).to eq [user.email]
      expect(mail.subject).to eq I18n.t('devise.mailer.unlock_instructions.subject')
      body = body_of(mail)
      expect(body).to include('excessive number of unsuccessful sign in attempts')
      expect(body).to include("unlock_token=#{token}")
    end

    it 'sends invitation instructions with the accept link' do
      mail = described_class.invitation_instructions(user, token)
      expect(mail.to).to eq [user.email]
      expect(mail.subject).to eq I18n.t('devise.mailer.invitation_instructions.subject')
      body = body_of(mail)
      expect(body).to include("Hello #{user.email}")
      expect(body).to include("invitation_token=#{token}")
      expect(body).to include(I18n.t('devise.mailer.invitation_instructions.accept'))
    end
  end

  describe 'delivery' do
    around do |example|
      adapter = ActiveJob::Base.queue_adapter
      ActiveJob::Base.queue_adapter = :test
      user
      ActionMailer::Base.deliveries.clear
      example.run
    ensure
      ActiveJob::Base.queue_adapter = adapter
      ActionMailer::Base.deliveries.clear
    end

    it 'deliver_now puts exactly one message into deliveries' do
      expect { described_class.reset_password_instructions(user, 'x').deliver_now }
        .to change { ActionMailer::Base.deliveries.size }.by(1)
      expect(ActionMailer::Base.deliveries.last.to).to eq [user.email]
    end

    it 'deliver_later enqueues a mail job without sending' do
      expect { described_class.reset_password_instructions(user, 'x').deliver_later }
        .to have_enqueued_mail(described_class, :reset_password_instructions)
      expect(ActionMailer::Base.deliveries).to be_empty
    end
  end
end
