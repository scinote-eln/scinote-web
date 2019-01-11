# frozen_string_literal: true

module Service
  def call(*args)
    new(*args).call
  end
end
