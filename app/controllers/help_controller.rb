class HelpController < ApplicationController
  
  def download_manual
    send_file(
      "#{Rails.root}/public/downloads/G-LMMD-0031316-FS-1-0.docx",
      filename: "SciNote Fact Sheet.docx",
      type: "application/docx"
    )
  end

end
