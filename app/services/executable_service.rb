# frozen_string_literal: true

module ExecutableService
  def execute(*args)
    new(*args).execute
  end
end
