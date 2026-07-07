# frozen_string_literal: true

class LabelTemplatesPreviewService
  extend Service

  attr_reader :error, :preview

  def initialize(params, user)
    @user = user
    @params = params
  end

  def generate_zpl_preview!
    if ENV['LABEL_PREVIEW_URL'].present?
      generate_zpl_preview_from_url!
    else
      generate_zpl_preview_from_lambda!
    end
  end

  private

  def generate_zpl_preview_from_url!
    resp = HTTParty.post(
      ENV['LABEL_PREVIEW_URL'],
      body: {
        content: @params[:zpl],
        width: @params[:width],
        height: @params[:height],
        density: @params[:density]
      }.to_json,
      headers: { 'Content-Type' => 'application/json' }
    )

    if resp.success?
      @preview = resp.body
    else
      @error = resp.body.presence || I18n.t('label_templates.label_preview.error_html')
    end
  rescue StandardError => e
    @error = e.message
  end

  def generate_zpl_preview_from_lambda!
    client = Aws::Lambda::Client.new(region: ENV['AWS_REGION'])
    resp = client.invoke(
      function_name: 'BinaryKitsZplViewer',
      invocation_type: 'RequestResponse',
      log_type: 'Tail',
      payload:
        "{ \"content\": #{@params[:zpl].to_json},"\
        "\"width\": #{@params[:width]},"\
        "\"height\": #{@params[:height]},"\
        "\"density\": #{@params[:density]} "\
        "}"
    )

    if resp.function_error.nil?
      @preview = resp.payload.string.delete('"')
    else
      begin
        error_response = JSON.parse(resp.payload.string)
        @error = error_response['errorMessage']
      rescue JSON::ParserError
        @error = resp.function_error
      end
    end
  end
end
