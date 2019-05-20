class HelpController < ApplicationController
  
  def download_manual
    send_file(
      "#{Rails.root}/public/downloads/testdownload.pdf",
      filename: "testdownload.pdf",
      type: "application/pdf",
      disposition: "attachment"
    )
  end

end
