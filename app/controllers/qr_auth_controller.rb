# frozen_string_literal: true

class QrAuthController < ApplicationController
  before_action :set_user, :create_doorkeeper_application, :create_authentication_poc_qr_code

  def index; end

  private

  def create_doorkeeper_application
    doorkeeper_application = Doorkeeper::Application.last

    authorization_code = doorkeeper_application.access_grants.create(
      resource_owner_id: @user.id,
      redirect_uri: doorkeeper_application.redirect_uri,
      expires_in: 10.minutes
    ).token

    @doorkeeper_application = {
      user_name: @user.name,
      user_email: @user.email,
      client_id: doorkeeper_application.uid,
      client_secret: doorkeeper_application.secret,
      code: authorization_code,
      redirect_uri: doorkeeper_application.redirect_uri,
      token_endpoint: "#{request.env['HTTP_HOST']}/oauth/token"
    }
  end

  def create_authentication_poc_qr_code
    qrcode = RQRCode::QRCode.new(@doorkeeper_application.as_json.to_s)

    png = qrcode.as_png(
      bit_depth: 1,
      border_modules: 4,
      color_mode: ChunkyPNG::COLOR_GRAYSCALE,
      color: 'black',
      file: nil,
      fill: 'white',
      module_px_size: 6,
      resize_exactly_to: false,
      resize_gte_to: false,
      size: 120
    )

    @user.qr_auth_code = Base64.encode64(png.to_s)
    @user.save
  end

  def set_user
    @user = current_user
  end
end
