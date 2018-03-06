SELECT DISTINCT
 repository_rows.*,
 users.full_name AS user_full_name,
 values.text_value AS text_value,
 values.date_value AS date_value,
 values.list_value AS list_value
 FROM repository_rows
 INNER JOIN (
   SELECT users.*
   FROM users
 ) AS users
 ON users.id = repository_rows.created_by_id
 LEFT OUTER JOIN (
   SELECT repository_cells.repository_row_id,
          repository_text_values.data AS text_value,
          to_char(repository_date_values.data, 'DD.MM.YYYY HH24:MI') AS date_value,
          ( SELECT repository_list_items.data
            FROM repository_list_items
            WHERE repository_list_items.id = repository_list_values.repository_list_item_id ) AS list_value
   FROM repository_cells
   INNER JOIN repository_text_values
   ON repository_text_values.id = repository_cells.value_id
   FULL OUTER JOIN repository_date_values
   ON repository_date_values.id = repository_cells.value_id
   FUll OUTER JOIN repository_list_values
   ON repository_list_values.id = repository_cells.value_id
 ) AS values
 ON values.repository_row_id = repository_rows.id
