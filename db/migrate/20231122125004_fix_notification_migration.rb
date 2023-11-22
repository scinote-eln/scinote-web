class FixNotificationMigration < ActiveRecord::Migration[7.0]
  def up
    Notification.find_each do |notification|
      parsed_params = JSON.parse(notification.params)
      parsed_params.delete('_aj_symbol_keys')
      notification.update!(params: parsed_params.symbolize_keys)
    end
  end
end
