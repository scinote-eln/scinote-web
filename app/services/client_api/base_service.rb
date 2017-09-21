module ClientApi
  class BaseService
    attr_accessor :current_user, :params

    def initialize(args)
      @current_user = args.fetch(:current_user) { raise StandardError }
      @params = (args.fetch(:params) { {} }).dup
    end

    private

    def error(message, http_status = nil)
      result = {
        message: message,
        status: :error
      }

      result[:http_status] = http_status if http_status
      result
    end

    def success(pass_back = {})
      pass_back[:status] = :success
      pass_back
    end
  end
end
