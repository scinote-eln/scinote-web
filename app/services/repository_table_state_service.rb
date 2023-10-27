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
    loaded = RepositoryTableState.where(user: @user, repository: @repository).take
    loaded = create_default_state unless loaded&.state.present? &&
                                         loaded.state['length'].to_i.positive? &&
                                         loaded.state['order'] &&
                                         loaded.state['columns'] &&
                                         loaded.state['ColReorder'] &&
                                         loaded.state.dig('columns', 1, 'visible') == true &&
                                         loaded.state.dig('columns', 3, 'visible') == true
    loaded
  end

  def update_state(state)
    saved_state = load_state
    state['order'] = @repository.default_table_state['order'] if state.dig('order', 0, 0).to_i < 1

    return if saved_state.state.except('time') == state.except('time')

    saved_state.update(state: state)
  end

  def create_default_state
    # Destroy any state object before recreating a new one
    RepositoryTableState.where(user: @user, repository: @repository).destroy_all

    RepositoryTableState.create(
      user: @user,
      repository: @repository,
      state: generate_default_state
    )
  end

  private

  def generate_default_state
    default_columns_num = @repository.default_columns_count

    # This state should be strings-only
    state = @repository.default_table_state.deep_dup
    @repository.repository_columns.each_with_index do |_, index|
      real_index = default_columns_num + index
      state['columns'][real_index] = Constants::REPOSITORY_TABLE_STATE_CUSTOM_COLUMN_TEMPLATE
      state['ColReorder'] << real_index
    end
    state['time'] = Time.new.to_i
    state
  end
end
