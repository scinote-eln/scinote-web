module MailerHelper
  # This method receives a HTML (as String), and
  # prepends the server URL in front of URLs/paths
  def prepend_server_url_to_links(html)
    html_doc = Nokogiri::HTML.fragment(html)
    links = html_doc.search('a')
    links.each do |link|
      href = link.attribute('href')
      href.value = prepend_server_url(href.value) if href.present?
    end
    html_doc.to_html
  end

  private

  def prepend_server_url(href)
    return href if href.start_with? Rails.application.config.action_mailer.default_url_options[:host]

    new_href = ''
    unless Rails.application.config.action_mailer.default_url_options[:host].start_with?('http://', 'https://')
      new_href += 'http://'
    end
    new_href += Rails.application.config.action_mailer.default_url_options[:host]
    new_href += ((href.start_with? '/') ? '' : '/')
    new_href += href
    new_href
  end
end
