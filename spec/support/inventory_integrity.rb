# frozen_string_literal: true

# Inventory integrity (mandatory columns, uniqueness) is switchable per instance (SCI-13751).
# Specs run with it enabled; examples that cover the disabled state stub it to false.
RSpec.configure do |config|
  config.before do
    allow(RepositoryBase).to receive(:inventory_integrity_enabled?).and_return(true)
  end
end
