class RepositoryTableStateService

  attr_reader :user, :repository

  def initialize(user, repository)
    @user = user
    @repository = repository
  end

  # We're using Constants::REPOSITORY_TABLE_DEFAULT_STATE as a reference for
  # default table state; this Ruby Hash makes heavy use of Ruby symbols
  # notation; HOWEVER, the state that is saved on the RepositoryTableState
  # record, has EVERYTHING (booleans, symbols, keys, ...) saved as Strings.

  def load_state
    state = RepositoryTableState.where(user: @user, repository: @repository).take
    if state.blank?
      state = self.create_default_state
    end
    state
  end

  def update_state(state)
    self.load_state
        .update(state: state)
  end

  def create_default_state
    # Destroy any state object before recreating a new one
    RepositoryTableState.where(user: @user, repository: @repository).destroy_all

    return RepositoryTableState.create(
      user: @user,
      repository: @repository,
      state: generate_default_state
    )
  end

  private

  def generate_default_state
    default_columns_num =
      Constants::REPOSITORY_TABLE_DEFAULT_STATE[:length]

    # This state should be strings-only
    state = HashUtil.deep_stringify_keys_and_values(
      Constants::REPOSITORY_TABLE_DEFAULT_STATE
    )
    repository.repository_columns.each_with_index do |_, index|
      real_index = default_columns_num + index
      state['columns'][real_index.to_s] =
        HashUtil.deep_stringify_keys_and_values(
          Constants::REPOSITORY_TABLE_STATE_CUSTOM_COLUMN_TEMPLATE
        )
      state['ColReorder'] << real_index.to_s
    end
    state['length'] = state['columns'].length.to_s
    state['time'] = Time.new.to_i.to_s
    state
  end
end
