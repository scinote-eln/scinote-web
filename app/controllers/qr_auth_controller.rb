class QrAuthController < ApplicationController
  def index
    @user = current_user
    qrcode = RQRCode::QRCode.new(@user.full_name, "1")

    png = qrcode.as_png(
      bit_depth: 1,
      border_modules: 4,
      color_mode: ChunkyPNG::COLOR_GRAYSCALE,
      color: "black",
      file: nil,
      fill: "white",
      module_px_size: 6,
      resize_exactly_to: false,
      resize_gte_to: false,
      size: 120
    )
    
    @user = current_user
    @user.qr_auth_code = Base64.encode64(png.to_s)
    @user.save
  end
end
