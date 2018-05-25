class ClearDiscardedRepositoriesJob
  class << self
    def perform_later
      Repository.with_discarded.discarded.destroy_all
    end

    handle_asynchronously :perform_later,
                          queue: :clear_discarded_repositories,
                          priority: 20
 end
end
