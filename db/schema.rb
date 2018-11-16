# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20181008130519) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "pg_trgm"
  enable_extension "btree_gist"

  create_table "activities", id: :serial, force: :cascade do |t|
    t.integer "my_module_id"
    t.integer "user_id"
    t.integer "type_of", null: false
    t.string "message", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "project_id", null: false
    t.integer "experiment_id"
    t.index ["created_at"], name: "index_activities_on_created_at"
    t.index ["experiment_id"], name: "index_activities_on_experiment_id"
    t.index ["my_module_id"], name: "index_activities_on_my_module_id"
    t.index ["project_id"], name: "index_activities_on_project_id"
    t.index ["type_of"], name: "index_activities_on_type_of"
    t.index ["user_id"], name: "index_activities_on_user_id"
  end

  create_table "asset_text_data", id: :serial, force: :cascade do |t|
    t.text "data", null: false
    t.integer "asset_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.tsvector "data_vector"
    t.index ["asset_id"], name: "index_asset_text_data_on_asset_id", unique: true
    t.index ["data_vector"], name: "index_asset_text_data_on_data_vector", using: :gin
  end

  create_table "assets", id: :serial, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "file_file_name"
    t.string "file_content_type"
    t.integer "file_file_size"
    t.datetime "file_updated_at"
    t.integer "created_by_id"
    t.integer "last_modified_by_id"
    t.integer "estimated_size", default: 0, null: false
    t.boolean "file_present", default: false, null: false
    t.string "lock", limit: 1024
    t.integer "lock_ttl"
    t.integer "version", default: 1
    t.boolean "file_processing"
    t.integer "team_id"
    t.index "trim_html_tags((file_file_name)::text) gin_trgm_ops", name: "index_assets_on_file_file_name", using: :gin
    t.index ["created_at"], name: "index_assets_on_created_at"
    t.index ["created_by_id"], name: "index_assets_on_created_by_id"
    t.index ["last_modified_by_id"], name: "index_assets_on_last_modified_by_id"
    t.index ["team_id"], name: "index_assets_on_team_id"
  end

  create_table "checklist_items", id: :serial, force: :cascade do |t|
    t.string "text", null: false
    t.boolean "checked", default: false, null: false
    t.integer "checklist_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "created_by_id"
    t.integer "last_modified_by_id"
    t.integer "position"
    t.index "trim_html_tags((text)::text) gin_trgm_ops", name: "index_checklist_items_on_text", using: :gin
    t.index ["checklist_id"], name: "index_checklist_items_on_checklist_id"
    t.index ["created_by_id"], name: "index_checklist_items_on_created_by_id"
    t.index ["last_modified_by_id"], name: "index_checklist_items_on_last_modified_by_id"
  end

  create_table "checklists", id: :serial, force: :cascade do |t|
    t.string "name", null: false
    t.integer "step_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "created_by_id"
    t.integer "last_modified_by_id"
    t.index "trim_html_tags((name)::text) gin_trgm_ops", name: "index_checklists_on_name", using: :gin
    t.index ["created_by_id"], name: "index_checklists_on_created_by_id"
    t.index ["last_modified_by_id"], name: "index_checklists_on_last_modified_by_id"
    t.index ["step_id"], name: "index_checklists_on_step_id"
  end

  create_table "comments", id: :serial, force: :cascade do |t|
    t.string "message", null: false
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "last_modified_by_id"
    t.string "type"
    t.integer "associated_id"
    t.index "trim_html_tags((message)::text) gin_trgm_ops", name: "index_comments_on_message", using: :gin
    t.index ["associated_id"], name: "index_comments_on_associated_id"
    t.index ["created_at"], name: "index_comments_on_created_at"
    t.index ["last_modified_by_id"], name: "index_comments_on_last_modified_by_id"
    t.index ["type"], name: "index_comments_on_type"
    t.index ["user_id"], name: "index_comments_on_user_id"
  end

  create_table "connections", id: :serial, force: :cascade do |t|
    t.integer "input_id", null: false
    t.integer "output_id", null: false
    t.index ["input_id"], name: "index_connections_on_input_id"
    t.index ["output_id"], name: "index_connections_on_output_id"
  end

  create_table "custom_fields", id: :serial, force: :cascade do |t|
    t.string "name", null: false
    t.integer "user_id", null: false
    t.integer "team_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "last_modified_by_id"
    t.index ["last_modified_by_id"], name: "index_custom_fields_on_last_modified_by_id"
    t.index ["team_id"], name: "index_custom_fields_on_team_id"
    t.index ["user_id"], name: "index_custom_fields_on_user_id"
  end

  create_table "delayed_jobs", id: :serial, force: :cascade do |t|
    t.integer "priority", default: 0, null: false
    t.integer "attempts", default: 0, null: false
    t.text "handler", null: false
    t.text "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string "locked_by"
    t.string "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["priority", "run_at"], name: "delayed_jobs_priority"
    t.index ["queue"], name: "delayed_jobs_queue"
  end

  create_table "experiments", id: :serial, force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.integer "project_id", null: false
    t.integer "created_by_id", null: false
    t.integer "last_modified_by_id", null: false
    t.boolean "archived", default: false, null: false
    t.integer "archived_by_id"
    t.datetime "archived_on"
    t.integer "restored_by_id"
    t.datetime "restored_on"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "workflowimg_file_name"
    t.string "workflowimg_content_type"
    t.integer "workflowimg_file_size"
    t.datetime "workflowimg_updated_at"
    t.index ["archived_by_id"], name: "index_experiments_on_archived_by_id"
    t.index ["created_by_id"], name: "index_experiments_on_created_by_id"
    t.index ["last_modified_by_id"], name: "index_experiments_on_last_modified_by_id"
    t.index ["name"], name: "index_experiments_on_name"
    t.index ["project_id"], name: "index_experiments_on_project_id"
    t.index ["restored_by_id"], name: "index_experiments_on_restored_by_id"
  end

  create_table "my_module_groups", id: :serial, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "created_by_id"
    t.integer "experiment_id", default: 0, null: false
    t.index ["created_by_id"], name: "index_my_module_groups_on_created_by_id"
    t.index ["experiment_id"], name: "index_my_module_groups_on_experiment_id"
  end

  create_table "my_module_repository_rows", id: :serial, force: :cascade do |t|
    t.bigint "repository_row_id", null: false
    t.integer "my_module_id"
    t.integer "assigned_by_id", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["my_module_id", "repository_row_id"], name: "index_my_module_ids_repository_row_ids"
    t.index ["repository_row_id"], name: "index_my_module_repository_rows_on_repository_row_id"
  end

  create_table "my_module_tags", id: :serial, force: :cascade do |t|
    t.integer "my_module_id"
    t.integer "tag_id"
    t.integer "created_by_id"
    t.index ["created_by_id"], name: "index_my_module_tags_on_created_by_id"
    t.index ["my_module_id"], name: "index_my_module_tags_on_my_module_id"
    t.index ["tag_id"], name: "index_my_module_tags_on_tag_id"
  end

  create_table "my_modules", id: :serial, force: :cascade do |t|
    t.string "name", null: false
    t.datetime "due_date"
    t.string "description"
    t.integer "x", default: 0, null: false
    t.integer "y", default: 0, null: false
    t.integer "my_module_group_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "archived", default: false, null: false
    t.datetime "archived_on"
    t.integer "created_by_id"
    t.integer "last_modified_by_id"
    t.integer "archived_by_id"
    t.integer "restored_by_id"
    t.datetime "restored_on"
    t.integer "nr_of_assigned_samples", default: 0
    t.integer "workflow_order", default: -1, null: false
    t.integer "experiment_id", default: 0, null: false
    t.integer "state", limit: 2, default: 0
    t.datetime "completed_on"
    t.index "trim_html_tags((description)::text) gin_trgm_ops", name: "index_my_modules_on_description", using: :gin
    t.index "trim_html_tags((name)::text) gin_trgm_ops", name: "index_my_modules_on_name", using: :gin
    t.index ["archived_by_id"], name: "index_my_modules_on_archived_by_id"
    t.index ["created_by_id"], name: "index_my_modules_on_created_by_id"
    t.index ["experiment_id"], name: "index_my_modules_on_experiment_id"
    t.index ["last_modified_by_id"], name: "index_my_modules_on_last_modified_by_id"
    t.index ["my_module_group_id"], name: "index_my_modules_on_my_module_group_id"
    t.index ["restored_by_id"], name: "index_my_modules_on_restored_by_id"
  end

  create_table "notifications", id: :serial, force: :cascade do |t|
    t.string "title"
    t.string "message"
    t.integer "type_of", null: false
    t.integer "generator_user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_notifications_on_created_at"
  end

  create_table "oauth_access_grants", force: :cascade do |t|
    t.integer "resource_owner_id", null: false
    t.bigint "application_id", null: false
    t.string "token", null: false
    t.integer "expires_in", null: false
    t.text "redirect_uri", null: false
    t.datetime "created_at", null: false
    t.datetime "revoked_at"
    t.string "scopes"
    t.index ["application_id"], name: "index_oauth_access_grants_on_application_id"
    t.index ["token"], name: "index_oauth_access_grants_on_token", unique: true
  end

  create_table "oauth_access_tokens", force: :cascade do |t|
    t.integer "resource_owner_id"
    t.bigint "application_id"
    t.text "token", null: false
    t.string "refresh_token"
    t.integer "expires_in"
    t.datetime "revoked_at"
    t.datetime "created_at", null: false
    t.string "scopes"
    t.string "previous_refresh_token", default: "", null: false
    t.index ["application_id"], name: "index_oauth_access_tokens_on_application_id"
    t.index ["refresh_token"], name: "index_oauth_access_tokens_on_refresh_token", unique: true
    t.index ["resource_owner_id"], name: "index_oauth_access_tokens_on_resource_owner_id"
    t.index ["token"], name: "index_oauth_access_tokens_on_token", unique: true
  end

  create_table "oauth_applications", force: :cascade do |t|
    t.string "name", null: false
    t.string "uid", null: false
    t.string "secret", null: false
    t.text "redirect_uri", null: false
    t.string "scopes", default: "", null: false
    t.boolean "confidential", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["uid"], name: "index_oauth_applications_on_uid", unique: true
  end

  create_table "projects", id: :serial, force: :cascade do |t|
    t.string "name", null: false
    t.integer "visibility", default: 0, null: false
    t.datetime "due_date"
    t.integer "team_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "archived", default: false, null: false
    t.datetime "archived_on"
    t.integer "created_by_id"
    t.integer "last_modified_by_id"
    t.integer "archived_by_id"
    t.integer "restored_by_id"
    t.datetime "restored_on"
    t.string "experiments_order"
    t.index "trim_html_tags((name)::text) gin_trgm_ops", name: "index_projects_on_name", using: :gin
    t.index ["archived_by_id"], name: "index_projects_on_archived_by_id"
    t.index ["created_by_id"], name: "index_projects_on_created_by_id"
    t.index ["last_modified_by_id"], name: "index_projects_on_last_modified_by_id"
    t.index ["restored_by_id"], name: "index_projects_on_restored_by_id"
    t.index ["team_id"], name: "index_projects_on_team_id"
  end

  create_table "protocol_keywords", id: :serial, force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "nr_of_protocols", default: 0
    t.integer "team_id", null: false
    t.index "trim_html_tags((name)::text) gin_trgm_ops", name: "index_protocol_keywords_on_name", using: :gin
    t.index ["team_id"], name: "index_protocol_keywords_on_team_id"
  end

  create_table "protocol_protocol_keywords", id: :serial, force: :cascade do |t|
    t.integer "protocol_id", null: false
    t.integer "protocol_keyword_id", null: false
    t.index ["protocol_id"], name: "index_protocol_protocol_keywords_on_protocol_id"
    t.index ["protocol_keyword_id"], name: "index_protocol_protocol_keywords_on_protocol_keyword_id"
  end

  create_table "protocols", id: :serial, force: :cascade do |t|
    t.string "name"
    t.text "authors"
    t.text "description"
    t.integer "added_by_id"
    t.integer "my_module_id"
    t.integer "team_id", null: false
    t.integer "protocol_type", default: 0, null: false
    t.integer "parent_id"
    t.datetime "parent_updated_at"
    t.integer "archived_by_id"
    t.datetime "archived_on"
    t.integer "restored_by_id"
    t.datetime "restored_on"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "published_on"
    t.integer "nr_of_linked_children", default: 0
    t.index "trim_html_tags((name)::text) gin_trgm_ops", name: "index_protocols_on_name", using: :gin
    t.index "trim_html_tags(authors) gin_trgm_ops", name: "index_protocols_on_authors", using: :gin
    t.index "trim_html_tags(description) gin_trgm_ops", name: "index_protocols_on_description", using: :gin
    t.index ["added_by_id"], name: "index_protocols_on_added_by_id"
    t.index ["archived_by_id"], name: "index_protocols_on_archived_by_id"
    t.index ["my_module_id"], name: "index_protocols_on_my_module_id"
    t.index ["parent_id"], name: "index_protocols_on_parent_id"
    t.index ["protocol_type"], name: "index_protocols_on_protocol_type"
    t.index ["restored_by_id"], name: "index_protocols_on_restored_by_id"
    t.index ["team_id"], name: "index_protocols_on_team_id"
  end

  create_table "report_elements", id: :serial, force: :cascade do |t|
    t.integer "position", null: false
    t.integer "type_of", null: false
    t.integer "sort_order", default: 0
    t.integer "report_id"
    t.integer "parent_id"
    t.integer "project_id"
    t.integer "my_module_id"
    t.integer "step_id"
    t.integer "result_id"
    t.integer "checklist_id"
    t.integer "asset_id"
    t.integer "table_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "experiment_id"
    t.integer "repository_id"
    t.index ["asset_id"], name: "index_report_elements_on_asset_id"
    t.index ["checklist_id"], name: "index_report_elements_on_checklist_id"
    t.index ["experiment_id"], name: "index_report_elements_on_experiment_id"
    t.index ["my_module_id"], name: "index_report_elements_on_my_module_id"
    t.index ["parent_id"], name: "index_report_elements_on_parent_id"
    t.index ["project_id"], name: "index_report_elements_on_project_id"
    t.index ["report_id"], name: "index_report_elements_on_report_id"
    t.index ["repository_id"], name: "index_report_elements_on_repository_id"
    t.index ["result_id"], name: "index_report_elements_on_result_id"
    t.index ["step_id"], name: "index_report_elements_on_step_id"
    t.index ["table_id"], name: "index_report_elements_on_table_id"
  end

  create_table "reports", id: :serial, force: :cascade do |t|
    t.string "name", null: false
    t.string "description"
    t.integer "project_id", null: false
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "last_modified_by_id"
    t.bigint "team_id"
    t.index "trim_html_tags((description)::text) gin_trgm_ops", name: "index_reports_on_description", using: :gin
    t.index "trim_html_tags((name)::text) gin_trgm_ops", name: "index_reports_on_name", using: :gin
    t.index ["last_modified_by_id"], name: "index_reports_on_last_modified_by_id"
    t.index ["project_id"], name: "index_reports_on_project_id"
    t.index ["team_id"], name: "index_reports_on_team_id"
    t.index ["user_id"], name: "index_reports_on_user_id"
  end

  create_table "repositories", id: :serial, force: :cascade do |t|
    t.integer "team_id"
    t.integer "created_by_id", null: false
    t.string "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "discarded_at"
    t.index ["discarded_at"], name: "index_repositories_on_discarded_at"
    t.index ["team_id"], name: "index_repositories_on_team_id"
  end

  create_table "repository_asset_values", force: :cascade do |t|
    t.bigint "asset_id"
    t.bigint "created_by_id"
    t.bigint "last_modified_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["asset_id"], name: "index_repository_asset_values_on_asset_id"
    t.index ["created_by_id"], name: "index_repository_asset_values_on_created_by_id"
    t.index ["last_modified_by_id"], name: "index_repository_asset_values_on_last_modified_by_id"
  end

  create_table "repository_cells", force: :cascade do |t|
    t.bigint "repository_row_id"
    t.integer "repository_column_id"
    t.string "value_type"
    t.bigint "value_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["repository_column_id"], name: "index_repository_cells_on_repository_column_id"
    t.index ["repository_row_id"], name: "index_repository_cells_on_repository_row_id"
    t.index ["value_type", "value_id"], name: "index_repository_cells_on_value_type_and_value_id"
  end

  create_table "repository_columns", force: :cascade do |t|
    t.integer "repository_id"
    t.integer "created_by_id", null: false
    t.string "name"
    t.integer "data_type", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["repository_id"], name: "index_repository_columns_on_repository_id"
  end

  create_table "repository_date_values", force: :cascade do |t|
    t.datetime "data"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "created_by_id", null: false
    t.integer "last_modified_by_id", null: false
  end

  create_table "repository_list_items", force: :cascade do |t|
    t.bigint "repository_id"
    t.bigint "repository_column_id"
    t.text "data", null: false
    t.bigint "created_by_id"
    t.bigint "last_modified_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index "trim_html_tags(data) gin_trgm_ops", name: "index_repository_list_items_on_data", using: :gin
    t.index ["created_by_id"], name: "index_repository_list_items_on_created_by_id"
    t.index ["last_modified_by_id"], name: "index_repository_list_items_on_last_modified_by_id"
    t.index ["repository_column_id"], name: "index_repository_list_items_on_repository_column_id"
    t.index ["repository_id"], name: "index_repository_list_items_on_repository_id"
  end

  create_table "repository_list_values", force: :cascade do |t|
    t.bigint "repository_list_item_id"
    t.bigint "created_by_id"
    t.bigint "last_modified_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_repository_list_values_on_created_by_id"
    t.index ["last_modified_by_id"], name: "index_repository_list_values_on_last_modified_by_id"
    t.index ["repository_list_item_id"], name: "index_repository_list_values_on_repository_list_item_id"
  end

  create_table "repository_rows", force: :cascade do |t|
    t.integer "repository_id"
    t.integer "created_by_id", null: false
    t.integer "last_modified_by_id", null: false
    t.string "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index "trim_html_tags((name)::text) gin_trgm_ops", name: "index_repository_rows_on_name", using: :gin
    t.index ["repository_id"], name: "index_repository_rows_on_repository_id"
  end

  create_table "repository_table_states", id: :serial, force: :cascade do |t|
    t.jsonb "state", null: false
    t.integer "user_id", null: false
    t.integer "repository_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["repository_id"], name: "index_repository_table_states_on_repository_id"
    t.index ["user_id"], name: "index_repository_table_states_on_user_id"
  end

  create_table "repository_text_values", force: :cascade do |t|
    t.string "data"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "created_by_id", null: false
    t.integer "last_modified_by_id", null: false
    t.index "trim_html_tags((data)::text) gin_trgm_ops", name: "index_repository_text_values_on_data", using: :gin
  end

  create_table "result_assets", id: :serial, force: :cascade do |t|
    t.integer "result_id", null: false
    t.integer "asset_id", null: false
    t.index ["result_id", "asset_id"], name: "index_result_assets_on_result_id_and_asset_id"
  end

  create_table "result_tables", id: :serial, force: :cascade do |t|
    t.integer "result_id", null: false
    t.integer "table_id", null: false
    t.index ["result_id", "table_id"], name: "index_result_tables_on_result_id_and_table_id"
  end

  create_table "result_texts", id: :serial, force: :cascade do |t|
    t.string "text", null: false
    t.integer "result_id", null: false
    t.index "trim_html_tags((text)::text) gin_trgm_ops", name: "index_result_texts_on_text", using: :gin
    t.index ["result_id"], name: "index_result_texts_on_result_id"
  end

  create_table "results", id: :serial, force: :cascade do |t|
    t.string "name"
    t.integer "my_module_id", null: false
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "archived", default: false, null: false
    t.datetime "archived_on"
    t.integer "last_modified_by_id"
    t.integer "archived_by_id"
    t.integer "restored_by_id"
    t.datetime "restored_on"
    t.index "trim_html_tags((name)::text) gin_trgm_ops", name: "index_results_on_name", using: :gin
    t.index ["archived_by_id"], name: "index_results_on_archived_by_id"
    t.index ["created_at"], name: "index_results_on_created_at"
    t.index ["last_modified_by_id"], name: "index_results_on_last_modified_by_id"
    t.index ["my_module_id"], name: "index_results_on_my_module_id"
    t.index ["restored_by_id"], name: "index_results_on_restored_by_id"
    t.index ["user_id"], name: "index_results_on_user_id"
  end

  create_table "sample_custom_fields", id: :serial, force: :cascade do |t|
    t.string "value", null: false
    t.integer "custom_field_id", null: false
    t.integer "sample_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index "trim_html_tags((value)::text) gin_trgm_ops", name: "index_sample_custom_fields_on_value", using: :gin
    t.index ["custom_field_id"], name: "index_sample_custom_fields_on_custom_field_id"
    t.index ["sample_id"], name: "index_sample_custom_fields_on_sample_id"
  end

  create_table "sample_groups", id: :serial, force: :cascade do |t|
    t.string "name", null: false
    t.string "color", default: "#ff0000", null: false
    t.integer "team_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "created_by_id"
    t.integer "last_modified_by_id"
    t.index "trim_html_tags((name)::text) gin_trgm_ops", name: "index_sample_groups_on_name", using: :gin
    t.index ["created_by_id"], name: "index_sample_groups_on_created_by_id"
    t.index ["last_modified_by_id"], name: "index_sample_groups_on_last_modified_by_id"
    t.index ["team_id"], name: "index_sample_groups_on_team_id"
  end

  create_table "sample_my_modules", id: :serial, force: :cascade do |t|
    t.integer "sample_id", null: false
    t.integer "my_module_id", null: false
    t.integer "assigned_by_id"
    t.datetime "assigned_on"
    t.index ["assigned_by_id"], name: "index_sample_my_modules_on_assigned_by_id"
    t.index ["my_module_id"], name: "index_sample_my_modules_on_my_module_id"
    t.index ["sample_id", "my_module_id"], name: "index_sample_my_modules_on_sample_id_and_my_module_id"
  end

  create_table "sample_types", id: :serial, force: :cascade do |t|
    t.string "name", null: false
    t.integer "team_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "created_by_id"
    t.integer "last_modified_by_id"
    t.index "trim_html_tags((name)::text) gin_trgm_ops", name: "index_sample_types_on_name", using: :gin
    t.index ["created_by_id"], name: "index_sample_types_on_created_by_id"
    t.index ["last_modified_by_id"], name: "index_sample_types_on_last_modified_by_id"
    t.index ["team_id"], name: "index_sample_types_on_team_id"
  end

  create_table "samples", id: :serial, force: :cascade do |t|
    t.string "name", null: false
    t.integer "user_id", null: false
    t.integer "team_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "sample_group_id"
    t.integer "sample_type_id"
    t.integer "last_modified_by_id"
    t.integer "nr_of_modules_assigned_to", default: 0
    t.index "trim_html_tags((name)::text) gin_trgm_ops", name: "index_samples_on_name", using: :gin
    t.index ["last_modified_by_id"], name: "index_samples_on_last_modified_by_id"
    t.index ["sample_group_id"], name: "index_samples_on_sample_group_id"
    t.index ["sample_type_id"], name: "index_samples_on_sample_type_id"
    t.index ["team_id"], name: "index_samples_on_team_id"
    t.index ["user_id"], name: "index_samples_on_user_id"
  end

  create_table "samples_tables", id: :serial, force: :cascade do |t|
    t.jsonb "status", default: {"time"=>0, "order"=>[[2, "desc"]], "start"=>0, "length"=>10, "search"=>{"regex"=>false, "smart"=>true, "search"=>"", "caseInsensitive"=>true}, "columns"=>[{"search"=>{"regex"=>false, "smart"=>true, "search"=>"", "caseInsensitive"=>true}, "visible"=>true}, {"search"=>{"regex"=>false, "smart"=>true, "search"=>"", "caseInsensitive"=>true}, "visible"=>true}, {"search"=>{"regex"=>false, "smart"=>true, "search"=>"", "caseInsensitive"=>true}, "visible"=>true}, {"search"=>{"regex"=>false, "smart"=>true, "search"=>"", "caseInsensitive"=>true}, "visible"=>true}, {"search"=>{"regex"=>false, "smart"=>true, "search"=>"", "caseInsensitive"=>true}, "visible"=>true}, {"search"=>{"regex"=>false, "smart"=>true, "search"=>"", "caseInsensitive"=>true}, "visible"=>true}, {"search"=>{"regex"=>false, "smart"=>true, "search"=>"", "caseInsensitive"=>true}, "visible"=>true}], "assigned"=>"all", "ColReorder"=>[0, 1, 2, 3, 4, 5, 6]}, null: false
    t.integer "user_id", null: false
    t.integer "team_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["team_id"], name: "index_samples_tables_on_team_id"
    t.index ["user_id"], name: "index_samples_tables_on_user_id"
  end

  create_table "settings", id: :serial, force: :cascade do |t|
    t.text "type", null: false
    t.jsonb "values", default: {}, null: false
    t.index ["type"], name: "index_settings_on_type", unique: true
  end

  create_table "step_assets", id: :serial, force: :cascade do |t|
    t.integer "step_id", null: false
    t.integer "asset_id", null: false
    t.index ["step_id", "asset_id"], name: "index_step_assets_on_step_id_and_asset_id"
  end

  create_table "step_tables", id: :serial, force: :cascade do |t|
    t.integer "step_id", null: false
    t.integer "table_id", null: false
    t.index ["step_id", "table_id"], name: "index_step_tables_on_step_id_and_table_id", unique: true
  end

  create_table "steps", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "description"
    t.integer "position", null: false
    t.boolean "completed", null: false
    t.datetime "completed_on"
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "last_modified_by_id"
    t.integer "protocol_id", null: false
    t.index "trim_html_tags((description)::text) gin_trgm_ops", name: "index_steps_on_description", using: :gin
    t.index "trim_html_tags((name)::text) gin_trgm_ops", name: "index_steps_on_name", using: :gin
    t.index ["created_at"], name: "index_steps_on_created_at"
    t.index ["last_modified_by_id"], name: "index_steps_on_last_modified_by_id"
    t.index ["position"], name: "index_steps_on_position"
    t.index ["protocol_id"], name: "index_steps_on_protocol_id"
    t.index ["user_id"], name: "index_steps_on_user_id"
  end

  create_table "tables", id: :serial, force: :cascade do |t|
    t.binary "contents", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "created_by_id"
    t.integer "last_modified_by_id"
    t.tsvector "data_vector"
    t.string "name", default: ""
    t.integer "team_id"
    t.index "trim_html_tags((name)::text) gin_trgm_ops", name: "index_tables_on_name", using: :gin
    t.index ["created_at"], name: "index_tables_on_created_at"
    t.index ["created_by_id"], name: "index_tables_on_created_by_id"
    t.index ["data_vector"], name: "index_tables_on_data_vector", using: :gin
    t.index ["last_modified_by_id"], name: "index_tables_on_last_modified_by_id"
    t.index ["team_id"], name: "index_tables_on_team_id"
  end

  create_table "tags", id: :serial, force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "color", default: "#ff0000", null: false
    t.integer "project_id", null: false
    t.integer "created_by_id"
    t.integer "last_modified_by_id"
    t.index "trim_html_tags((name)::text) gin_trgm_ops", name: "index_tags_on_name", using: :gin
    t.index ["created_by_id"], name: "index_tags_on_created_by_id"
    t.index ["last_modified_by_id"], name: "index_tags_on_last_modified_by_id"
    t.index ["project_id"], name: "index_tags_on_project_id"
  end

  create_table "teams", id: :serial, force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "created_by_id"
    t.integer "last_modified_by_id"
    t.string "description"
    t.bigint "space_taken", default: 1048576, null: false
    t.index ["created_by_id"], name: "index_teams_on_created_by_id"
    t.index ["last_modified_by_id"], name: "index_teams_on_last_modified_by_id"
    t.index ["name"], name: "index_teams_on_name"
  end

  create_table "temp_files", id: :serial, force: :cascade do |t|
    t.string "session_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "file_file_name"
    t.string "file_content_type"
    t.integer "file_file_size"
    t.datetime "file_updated_at"
  end

  create_table "tiny_mce_assets", id: :serial, force: :cascade do |t|
    t.string "image_file_name"
    t.string "image_content_type"
    t.integer "image_file_size"
    t.datetime "image_updated_at"
    t.integer "estimated_size", default: 0, null: false
    t.integer "step_id"
    t.integer "team_id"
    t.integer "result_text_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["result_text_id"], name: "index_tiny_mce_assets_on_result_text_id"
    t.index ["step_id"], name: "index_tiny_mce_assets_on_step_id"
    t.index ["team_id"], name: "index_tiny_mce_assets_on_team_id"
  end

  create_table "tokens", id: :serial, force: :cascade do |t|
    t.string "token", null: false
    t.integer "ttl", null: false
    t.integer "user_id", null: false
  end

  create_table "user_identities", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.string "provider", null: false
    t.string "uid", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["provider", "uid"], name: "index_user_identities_on_provider_and_uid", unique: true
    t.index ["user_id", "provider"], name: "index_user_identities_on_user_id_and_provider", unique: true
    t.index ["user_id"], name: "index_user_identities_on_user_id"
  end

  create_table "user_my_modules", id: :serial, force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "my_module_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "assigned_by_id"
    t.index ["assigned_by_id"], name: "index_user_my_modules_on_assigned_by_id"
    t.index ["my_module_id"], name: "index_user_my_modules_on_my_module_id"
    t.index ["user_id"], name: "index_user_my_modules_on_user_id"
  end

  create_table "user_notifications", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.integer "notification_id"
    t.boolean "checked", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["checked"], name: "index_user_notifications_on_checked"
    t.index ["notification_id"], name: "index_user_notifications_on_notification_id"
    t.index ["user_id"], name: "index_user_notifications_on_user_id"
  end

  create_table "user_projects", id: :serial, force: :cascade do |t|
    t.integer "role"
    t.integer "user_id", null: false
    t.integer "project_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "assigned_by_id"
    t.index ["assigned_by_id"], name: "index_user_projects_on_assigned_by_id"
    t.index ["project_id"], name: "index_user_projects_on_project_id"
    t.index ["user_id"], name: "index_user_projects_on_user_id"
  end

  create_table "user_teams", id: :serial, force: :cascade do |t|
    t.integer "role", default: 1, null: false
    t.integer "user_id", null: false
    t.integer "team_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "assigned_by_id"
    t.index ["assigned_by_id"], name: "index_user_teams_on_assigned_by_id"
    t.index ["team_id"], name: "index_user_teams_on_team_id"
    t.index ["user_id"], name: "index_user_teams_on_user_id"
  end

  create_table "users", id: :serial, force: :cascade do |t|
    t.string "full_name", null: false
    t.string "initials", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "avatar_file_name"
    t.string "avatar_content_type"
    t.integer "avatar_file_size"
    t.datetime "avatar_updated_at"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.string "invitation_token"
    t.datetime "invitation_created_at"
    t.datetime "invitation_sent_at"
    t.datetime "invitation_accepted_at"
    t.integer "invitation_limit"
    t.string "invited_by_type"
    t.integer "invited_by_id"
    t.integer "invitations_count", default: 0
    t.integer "current_team_id"
    t.string "authentication_token", limit: 30
    t.jsonb "settings", default: {}, null: false
    t.jsonb "variables", default: {}, null: false
    t.index "trim_html_tags((full_name)::text) gin_trgm_ops", name: "index_users_on_full_name", using: :gin
    t.index ["authentication_token"], name: "index_users_on_authentication_token", unique: true
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["invitation_token"], name: "index_users_on_invitation_token", unique: true
    t.index ["invitations_count"], name: "index_users_on_invitations_count"
    t.index ["invited_by_id"], name: "index_users_on_invited_by_id"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "view_states", force: :cascade do |t|
    t.jsonb "state"
    t.bigint "user_id"
    t.string "viewable_type"
    t.bigint "viewable_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_view_states_on_user_id"
    t.index ["viewable_type", "viewable_id"], name: "index_view_states_on_viewable_type_and_viewable_id"
  end

  create_table "wopi_actions", id: :serial, force: :cascade do |t|
    t.string "action", null: false
    t.string "extension", null: false
    t.string "urlsrc", null: false
    t.integer "wopi_app_id", null: false
    t.index ["extension", "action"], name: "index_wopi_actions_on_extension_and_action"
  end

  create_table "wopi_apps", id: :serial, force: :cascade do |t|
    t.string "name", null: false
    t.string "icon", null: false
    t.integer "wopi_discovery_id", null: false
  end

  create_table "wopi_discoveries", id: :serial, force: :cascade do |t|
    t.integer "expires", null: false
    t.string "proof_key_mod", null: false
    t.string "proof_key_exp", null: false
    t.string "proof_key_old_mod", null: false
    t.string "proof_key_old_exp", null: false
  end

  create_table "zip_exports", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "zip_file_file_name"
    t.string "zip_file_content_type"
    t.integer "zip_file_file_size"
    t.datetime "zip_file_updated_at"
    t.index ["user_id"], name: "index_zip_exports_on_user_id"
  end

  add_foreign_key "activities", "experiments"
  add_foreign_key "activities", "my_modules"
  add_foreign_key "activities", "projects"
  add_foreign_key "activities", "users"
  add_foreign_key "asset_text_data", "assets"
  add_foreign_key "assets", "users", column: "created_by_id"
  add_foreign_key "assets", "users", column: "last_modified_by_id"
  add_foreign_key "checklist_items", "checklists"
  add_foreign_key "checklist_items", "users", column: "created_by_id"
  add_foreign_key "checklist_items", "users", column: "last_modified_by_id"
  add_foreign_key "checklists", "steps"
  add_foreign_key "checklists", "users", column: "created_by_id"
  add_foreign_key "checklists", "users", column: "last_modified_by_id"
  add_foreign_key "comments", "users"
  add_foreign_key "comments", "users", column: "last_modified_by_id"
  add_foreign_key "connections", "my_modules", column: "input_id"
  add_foreign_key "connections", "my_modules", column: "output_id"
  add_foreign_key "custom_fields", "teams"
  add_foreign_key "custom_fields", "users"
  add_foreign_key "custom_fields", "users", column: "last_modified_by_id"
  add_foreign_key "experiments", "users", column: "archived_by_id"
  add_foreign_key "experiments", "users", column: "created_by_id"
  add_foreign_key "experiments", "users", column: "last_modified_by_id"
  add_foreign_key "experiments", "users", column: "restored_by_id"
  add_foreign_key "my_module_groups", "experiments"
  add_foreign_key "my_module_groups", "users", column: "created_by_id"
  add_foreign_key "my_module_repository_rows", "users", column: "assigned_by_id"
  add_foreign_key "my_module_tags", "users", column: "created_by_id"
  add_foreign_key "my_modules", "experiments"
  add_foreign_key "my_modules", "my_module_groups"
  add_foreign_key "my_modules", "users", column: "archived_by_id"
  add_foreign_key "my_modules", "users", column: "created_by_id"
  add_foreign_key "my_modules", "users", column: "last_modified_by_id"
  add_foreign_key "my_modules", "users", column: "restored_by_id"
  add_foreign_key "notifications", "users", column: "generator_user_id"
  add_foreign_key "oauth_access_grants", "oauth_applications", column: "application_id"
  add_foreign_key "oauth_access_grants", "users", column: "resource_owner_id"
  add_foreign_key "oauth_access_tokens", "oauth_applications", column: "application_id"
  add_foreign_key "oauth_access_tokens", "users", column: "resource_owner_id"
  add_foreign_key "projects", "teams"
  add_foreign_key "projects", "users", column: "archived_by_id"
  add_foreign_key "projects", "users", column: "created_by_id"
  add_foreign_key "projects", "users", column: "last_modified_by_id"
  add_foreign_key "projects", "users", column: "restored_by_id"
  add_foreign_key "protocol_keywords", "teams"
  add_foreign_key "protocol_protocol_keywords", "protocol_keywords"
  add_foreign_key "protocol_protocol_keywords", "protocols"
  add_foreign_key "protocols", "my_modules"
  add_foreign_key "protocols", "protocols", column: "parent_id"
  add_foreign_key "protocols", "teams"
  add_foreign_key "protocols", "users", column: "added_by_id"
  add_foreign_key "protocols", "users", column: "archived_by_id"
  add_foreign_key "protocols", "users", column: "restored_by_id"
  add_foreign_key "report_elements", "assets"
  add_foreign_key "report_elements", "checklists"
  add_foreign_key "report_elements", "experiments"
  add_foreign_key "report_elements", "my_modules"
  add_foreign_key "report_elements", "projects"
  add_foreign_key "report_elements", "reports"
  add_foreign_key "report_elements", "results"
  add_foreign_key "report_elements", "steps"
  add_foreign_key "report_elements", "tables"
  add_foreign_key "reports", "projects"
  add_foreign_key "reports", "users"
  add_foreign_key "reports", "users", column: "last_modified_by_id"
  add_foreign_key "repositories", "users", column: "created_by_id"
  add_foreign_key "repository_asset_values", "users", column: "created_by_id"
  add_foreign_key "repository_asset_values", "users", column: "last_modified_by_id"
  add_foreign_key "repository_columns", "users", column: "created_by_id"
  add_foreign_key "repository_date_values", "users", column: "created_by_id"
  add_foreign_key "repository_date_values", "users", column: "last_modified_by_id"
  add_foreign_key "repository_list_items", "repositories"
  add_foreign_key "repository_list_items", "repository_columns"
  add_foreign_key "repository_list_items", "users", column: "created_by_id"
  add_foreign_key "repository_list_items", "users", column: "last_modified_by_id"
  add_foreign_key "repository_list_values", "users", column: "created_by_id"
  add_foreign_key "repository_list_values", "users", column: "last_modified_by_id"
  add_foreign_key "repository_rows", "users", column: "created_by_id"
  add_foreign_key "repository_rows", "users", column: "last_modified_by_id"
  add_foreign_key "repository_text_values", "users", column: "created_by_id"
  add_foreign_key "repository_text_values", "users", column: "last_modified_by_id"
  add_foreign_key "result_assets", "assets"
  add_foreign_key "result_assets", "results"
  add_foreign_key "result_tables", "results"
  add_foreign_key "result_tables", "tables"
  add_foreign_key "result_texts", "results"
  add_foreign_key "results", "my_modules"
  add_foreign_key "results", "users"
  add_foreign_key "results", "users", column: "archived_by_id"
  add_foreign_key "results", "users", column: "last_modified_by_id"
  add_foreign_key "results", "users", column: "restored_by_id"
  add_foreign_key "sample_custom_fields", "custom_fields"
  add_foreign_key "sample_custom_fields", "samples"
  add_foreign_key "sample_groups", "teams"
  add_foreign_key "sample_groups", "users", column: "created_by_id"
  add_foreign_key "sample_groups", "users", column: "last_modified_by_id"
  add_foreign_key "sample_my_modules", "my_modules"
  add_foreign_key "sample_my_modules", "samples"
  add_foreign_key "sample_my_modules", "users", column: "assigned_by_id"
  add_foreign_key "sample_types", "teams"
  add_foreign_key "sample_types", "users", column: "created_by_id"
  add_foreign_key "sample_types", "users", column: "last_modified_by_id"
  add_foreign_key "samples", "sample_groups"
  add_foreign_key "samples", "sample_types"
  add_foreign_key "samples", "teams"
  add_foreign_key "samples", "users"
  add_foreign_key "samples", "users", column: "last_modified_by_id"
  add_foreign_key "step_assets", "assets"
  add_foreign_key "step_assets", "steps"
  add_foreign_key "step_tables", "steps"
  add_foreign_key "step_tables", "tables"
  add_foreign_key "steps", "protocols"
  add_foreign_key "steps", "users"
  add_foreign_key "steps", "users", column: "last_modified_by_id"
  add_foreign_key "tables", "users", column: "created_by_id"
  add_foreign_key "tables", "users", column: "last_modified_by_id"
  add_foreign_key "tags", "projects"
  add_foreign_key "tags", "users", column: "created_by_id"
  add_foreign_key "tags", "users", column: "last_modified_by_id"
  add_foreign_key "teams", "users", column: "created_by_id"
  add_foreign_key "teams", "users", column: "last_modified_by_id"
  add_foreign_key "tokens", "users"
  add_foreign_key "user_my_modules", "my_modules"
  add_foreign_key "user_my_modules", "users"
  add_foreign_key "user_my_modules", "users", column: "assigned_by_id"
  add_foreign_key "user_notifications", "notifications"
  add_foreign_key "user_notifications", "users"
  add_foreign_key "user_projects", "projects"
  add_foreign_key "user_projects", "users"
  add_foreign_key "user_projects", "users", column: "assigned_by_id"
  add_foreign_key "user_teams", "teams"
  add_foreign_key "user_teams", "users"
  add_foreign_key "user_teams", "users", column: "assigned_by_id"
  add_foreign_key "users", "teams", column: "current_team_id"
  add_foreign_key "view_states", "users"
  add_foreign_key "wopi_actions", "wopi_apps"
  add_foreign_key "wopi_apps", "wopi_discoveries"
  add_foreign_key "zip_exports", "users"

  create_view "datatables_teams",  sql_definition: <<-SQL
      SELECT teams.id,
      teams.name,
      user_teams.role,
      ( SELECT count(*) AS count
             FROM user_teams user_teams_1
            WHERE (user_teams_1.team_id = teams.id)) AS members,
          CASE
              WHEN (teams.created_by_id = user_teams.user_id) THEN false
              ELSE true
          END AS can_be_left,
      user_teams.id AS user_team_id,
      user_teams.user_id
     FROM (teams
       JOIN user_teams ON ((teams.id = user_teams.team_id)));
  SQL

  create_view "datatables_reports", materialized: true,  sql_definition: <<-SQL
      SELECT DISTINCT ON (reports.id) reports.id,
      reports.name,
      projects.name AS project_name,
      ( SELECT users.full_name
             FROM users
            WHERE (users.id = reports.user_id)) AS created_by,
      ( SELECT users.full_name
             FROM users
            WHERE (users.id = reports.last_modified_by_id)) AS last_modified_by,
      reports.created_at,
      reports.updated_at,
      projects.archived AS project_archived,
      projects.visibility AS project_visibility,
      projects.id AS project_id,
      reports.team_id,
      ARRAY( SELECT DISTINCT user_teams_1.user_id
             FROM user_teams user_teams_1
            WHERE (user_teams_1.team_id = teams.id)) AS users_with_team_read_permissions,
      ARRAY( SELECT DISTINCT user_projects_1.user_id
             FROM user_projects user_projects_1
            WHERE (user_projects_1.project_id = projects.id)) AS users_with_project_read_permissions
     FROM ((((reports
       JOIN projects ON ((projects.id = reports.project_id)))
       JOIN user_projects ON ((user_projects.project_id = projects.id)))
       JOIN teams ON ((teams.id = projects.team_id)))
       JOIN user_teams ON ((user_teams.team_id = teams.id)));
  SQL

  add_index "datatables_reports", ["id"], name: "index_datatables_reports_on_id", unique: true
  add_index "datatables_reports", ["team_id"], name: "index_datatables_reports_on_team_id"

end
