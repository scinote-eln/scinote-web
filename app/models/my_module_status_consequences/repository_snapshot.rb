# frozen_string_literal: true

module MyModuleStatusConsequences
  class RepositorySnapshot < MyModuleStatusConsequence
    def call(my_module)
      my_module.assigned_repositories.each do |repo|
        repo.provision_snapshot(my_module)
      end
    end
  end
end
