# frozen_string_literal: true

class LabelTemplatesPreviewService
  extend Service

  attr_reader :error, :preview

  def initialize(zpl, user, params)
    @zpl = zpl
    @user = user
    @params = params
  end

  def generate_zpl_preview!
    client = Aws::Lambda::Client.new(region: ENV['AWS_REGION'])
    resp = client.invoke(
      function_name: 'BinaryKitsZplViewer',
      invocation_type: 'RequestResponse',
      log_type: 'Tail',
      payload: "{ \"content\": #{@zpl.to_json} }"
    )

    if resp.function_error.nil?
      @preview = resp.payload
    else
      @error = resp.function_error
    end
  end
end
