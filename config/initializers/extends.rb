# Extends class holds the arrays for the models enum fields
# so that can be extended in sub modules.

class Extends
  # To extend the enum fields in the engine you have to put in
  # lib/engine_name/engine.rb file as in the example:

  # > initializer 'add_additional enum values to my model' do
  # >   Extends::MY_ARRAY_OF_ENUM_VALUES.merge!(value1, value2, ....)
  # > end
  # >

  # Notification types. Should not be freezed, as modules might append to this.
  # !!!Check all addons for the correct order!!!
  NOTIFICATIONS_TYPES = { assignment: 0,
                          recent_changes: 1,
                          system_message: 2,
                          deliver: 5 }

  TASKS_STATES = { uncompleted: 0,
                   completed: 1 }
end
