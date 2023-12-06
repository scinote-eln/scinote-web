# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.0].define(version: 2023_11_28_123835) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "btree_gist"
  enable_extension "pg_trgm"
  enable_extension "plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", precision: nil, null: false
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "activities", force: :cascade do |t|
    t.bigint "my_module_id"
    t.bigint "owner_id"
    t.integer "type_of", null: false
    t.string "message"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.bigint "project_id"
    t.bigint "experiment_id"
    t.string "subject_type"
    t.bigint "subject_id"
    t.bigint "team_id"
    t.integer "group_type"
    t.jsonb "values"
    t.index ["created_at", "team_id"], name: "index_activities_on_created_at_and_team_id_and_no_project_id", order: { created_at: :desc }, where: "(project_id IS NULL)"
    t.index ["created_at"], name: "index_activities_on_created_at"
    t.index ["experiment_id"], name: "index_activities_on_experiment_id"
    t.index ["my_module_id"], name: "index_activities_on_my_module_id"
    t.index ["owner_id"], name: "index_activities_on_owner_id"
    t.index ["project_id"], name: "index_activities_on_project_id"
    t.index ["subject_type", "subject_id"], name: "index_activities_on_subject_type_and_subject_id"
    t.index ["team_id"], name: "index_activities_on_team_id"
    t.index ["type_of"], name: "index_activities_on_type_of"
  end

  create_table "activity_filters", force: :cascade do |t|
    t.string "name", null: false
    t.jsonb "filter", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "asset_text_data", force: :cascade do |t|
    t.text "data", null: false
    t.bigint "asset_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.tsvector "data_vector"
    t.index ["asset_id"], name: "index_asset_text_data_on_asset_id", unique: true
    t.index ["data_vector"], name: "index_asset_text_data_on_data_vector", using: :gin
  end

  create_table "assets", force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.bigint "created_by_id"
    t.bigint "last_modified_by_id"
    t.bigint "estimated_size", default: 0, null: false
    t.string "lock", limit: 1024
    t.integer "lock_ttl"
    t.integer "version", default: 1
    t.boolean "file_processing"
    t.integer "team_id"
    t.integer "file_image_quality"
    t.integer "view_mode", default: 0, null: false
    t.boolean "pdf_preview_processing", default: false
    t.index ["created_at"], name: "index_assets_on_created_at"
    t.index ["created_by_id"], name: "index_assets_on_created_by_id"
    t.index ["last_modified_by_id"], name: "index_assets_on_last_modified_by_id"
    t.index ["team_id"], name: "index_assets_on_team_id"
  end

  create_table "checklist_items", force: :cascade do |t|
    t.string "text", null: false
    t.boolean "checked", default: false, null: false
    t.bigint "checklist_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.bigint "created_by_id"
    t.bigint "last_modified_by_id"
    t.integer "position"
    t.index "trim_html_tags((text)::text) gin_trgm_ops", name: "index_checklist_items_on_text", using: :gin
    t.index ["checklist_id", "position"], name: "index_checklist_items_on_checklist_id_and_position", unique: true
    t.index ["checklist_id"], name: "index_checklist_items_on_checklist_id"
    t.index ["created_by_id"], name: "index_checklist_items_on_created_by_id"
    t.index ["last_modified_by_id"], name: "index_checklist_items_on_last_modified_by_id"
  end

  create_table "checklists", force: :cascade do |t|
    t.string "name", null: false
    t.bigint "step_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.bigint "created_by_id"
    t.bigint "last_modified_by_id"
    t.index "trim_html_tags((name)::text) gin_trgm_ops", name: "index_checklists_on_name", using: :gin
    t.index ["created_by_id"], name: "index_checklists_on_created_by_id"
    t.index ["last_modified_by_id"], name: "index_checklists_on_last_modified_by_id"
    t.index ["step_id"], name: "index_checklists_on_step_id"
  end

  create_table "comments", force: :cascade do |t|
    t.string "message", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.bigint "last_modified_by_id"
    t.string "type"
    t.integer "associated_id"
    t.bigint "unseen_by", default: [], array: true
    t.index "trim_html_tags((message)::text) gin_trgm_ops", name: "index_comments_on_message", using: :gin
    t.index ["associated_id"], name: "index_comments_on_associated_id"
    t.index ["created_at"], name: "index_comments_on_created_at"
    t.index ["last_modified_by_id"], name: "index_comments_on_last_modified_by_id"
    t.index ["type"], name: "index_comments_on_type"
    t.index ["user_id"], name: "index_comments_on_user_id"
  end

  create_table "connected_devices", force: :cascade do |t|
    t.string "uid"
    t.string "name"
    t.bigint "oauth_access_token_id", null: false
    t.json "metadata"
    t.datetime "last_seen_at", precision: nil
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["oauth_access_token_id"], name: "index_connected_devices_on_oauth_access_token_id"
  end

  create_table "connections", force: :cascade do |t|
    t.bigint "input_id", null: false
    t.bigint "output_id", null: false
    t.index ["input_id"], name: "index_connections_on_input_id"
    t.index ["output_id"], name: "index_connections_on_output_id"
  end

  create_table "delayed_jobs", force: :cascade do |t|
    t.integer "priority", default: 0, null: false
    t.integer "attempts", default: 0, null: false
    t.text "handler", null: false
    t.text "last_error"
    t.datetime "run_at", precision: nil
    t.datetime "locked_at", precision: nil
    t.datetime "failed_at", precision: nil
    t.string "locked_by"
    t.string "queue"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["priority", "run_at"], name: "delayed_jobs_priority"
    t.index ["queue"], name: "delayed_jobs_queue"
  end

  create_table "experiments", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.integer "project_id", null: false
    t.bigint "created_by_id", null: false
    t.bigint "last_modified_by_id", null: false
    t.boolean "archived", default: false, null: false
    t.bigint "archived_by_id"
    t.datetime "archived_on", precision: nil
    t.bigint "restored_by_id"
    t.datetime "restored_on", precision: nil
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.uuid "uuid"
    t.index "(('EX'::text || id)) gin_trgm_ops", name: "index_experiments_on_experiment_code", using: :gin
    t.index "trim_html_tags((name)::text) gin_trgm_ops", name: "index_experiments_on_name", using: :gin
    t.index "trim_html_tags(description) gin_trgm_ops", name: "index_experiments_on_description", using: :gin
    t.index ["archived"], name: "index_experiments_on_archived"
    t.index ["archived_by_id"], name: "index_experiments_on_archived_by_id"
    t.index ["created_by_id"], name: "index_experiments_on_created_by_id"
    t.index ["last_modified_by_id"], name: "index_experiments_on_last_modified_by_id"
    t.index ["project_id"], name: "index_experiments_on_project_id"
    t.index ["restored_by_id"], name: "index_experiments_on_restored_by_id"
  end

  create_table "hidden_repository_cell_reminders", force: :cascade do |t|
    t.bigint "repository_cell_id", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["repository_cell_id"], name: "index_hidden_repository_cell_reminders_on_repository_cell_id"
    t.index ["user_id"], name: "index_hidden_repository_cell_reminders_on_user_id"
  end

  create_table "label_printers", force: :cascade do |t|
    t.string "name", null: false
    t.string "description"
    t.integer "type_of", null: false
    t.integer "language_type", null: false
    t.string "host"
    t.integer "port"
    t.string "fluics_api_key"
    t.string "fluics_lid"
    t.string "current_print_job_ids", default: [], array: true
    t.integer "status", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "label_templates", force: :cascade do |t|
    t.string "name", null: false
    t.text "content", null: false
    t.boolean "default", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "description"
    t.integer "last_modified_by_id"
    t.integer "created_by_id"
    t.bigint "team_id"
    t.string "type"
    t.float "width_mm"
    t.float "height_mm"
    t.integer "unit", default: 0
    t.integer "density", default: 12
    t.index ["created_by_id"], name: "index_label_templates_on_created_by_id"
    t.index ["last_modified_by_id"], name: "index_label_templates_on_last_modified_by_id"
    t.index ["team_id"], name: "index_label_templates_on_team_id"
  end

  create_table "my_module_groups", force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.bigint "created_by_id"
    t.bigint "experiment_id", default: 0, null: false
    t.index ["created_by_id"], name: "index_my_module_groups_on_created_by_id"
    t.index ["experiment_id"], name: "index_my_module_groups_on_experiment_id"
  end

  create_table "my_module_repository_rows", force: :cascade do |t|
    t.bigint "repository_row_id", null: false
    t.integer "my_module_id"
    t.bigint "assigned_by_id", null: false
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.decimal "stock_consumption"
    t.bigint "repository_stock_unit_item_id"
    t.index ["my_module_id", "repository_row_id"], name: "index_my_module_ids_repository_row_ids", unique: true
    t.index ["repository_row_id"], name: "index_my_module_repository_rows_on_repository_row_id"
    t.index ["repository_stock_unit_item_id"], name: "index_on_repository_stock_unit_item_id"
  end

  create_table "my_module_status_conditions", force: :cascade do |t|
    t.bigint "my_module_status_id"
    t.string "type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["my_module_status_id"], name: "index_my_module_status_conditions_on_my_module_status_id"
  end

  create_table "my_module_status_consequences", force: :cascade do |t|
    t.bigint "my_module_status_id"
    t.string "type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["my_module_status_id"], name: "index_my_module_status_consequences_on_my_module_status_id"
  end

  create_table "my_module_status_flows", force: :cascade do |t|
    t.string "name", null: false
    t.string "description"
    t.integer "visibility", default: 0
    t.bigint "team_id"
    t.bigint "created_by_id"
    t.bigint "last_modified_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["team_id"], name: "index_my_module_status_flows_on_team_id"
    t.index ["visibility"], name: "index_my_module_status_flows_on_visibility"
  end

  create_table "my_module_status_implications", force: :cascade do |t|
    t.bigint "my_module_status_id"
    t.string "type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["my_module_status_id"], name: "index_my_module_status_implications_on_my_module_status_id"
  end

  create_table "my_module_statuses", force: :cascade do |t|
    t.string "name", null: false
    t.string "description"
    t.string "color", null: false
    t.bigint "my_module_status_flow_id"
    t.bigint "previous_status_id"
    t.bigint "created_by_id"
    t.bigint "last_modified_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["my_module_status_flow_id"], name: "index_my_module_statuses_on_my_module_status_flow_id"
    t.index ["previous_status_id"], name: "index_my_module_statuses_on_previous_status_id", unique: true
  end

  create_table "my_module_tags", force: :cascade do |t|
    t.integer "my_module_id"
    t.integer "tag_id"
    t.bigint "created_by_id"
    t.index ["created_by_id"], name: "index_my_module_tags_on_created_by_id"
    t.index ["my_module_id"], name: "index_my_module_tags_on_my_module_id"
    t.index ["tag_id"], name: "index_my_module_tags_on_tag_id"
  end

  create_table "my_modules", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "due_date", precision: nil
    t.string "description"
    t.integer "x", default: 0, null: false
    t.integer "y", default: 0, null: false
    t.bigint "my_module_group_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "archived", default: false, null: false
    t.datetime "archived_on", precision: nil
    t.bigint "created_by_id"
    t.bigint "last_modified_by_id"
    t.bigint "archived_by_id"
    t.bigint "restored_by_id"
    t.datetime "restored_on", precision: nil
    t.integer "workflow_order", default: -1, null: false
    t.bigint "experiment_id", default: 0, null: false
    t.integer "state", limit: 2, default: 0
    t.datetime "completed_on", precision: nil
    t.datetime "started_on", precision: nil
    t.bigint "my_module_status_id"
    t.boolean "status_changing", default: false
    t.bigint "changing_from_my_module_status_id"
    t.jsonb "last_transition_error"
    t.integer "provisioning_status"
    t.boolean "due_date_notification_sent", default: false
    t.index "(('TA'::text || id)) gin_trgm_ops", name: "index_my_modules_on_my_module_code", using: :gin
    t.index "trim_html_tags((description)::text) gin_trgm_ops", name: "index_my_modules_on_description", using: :gin
    t.index "trim_html_tags((name)::text) gin_trgm_ops", name: "index_my_modules_on_name", using: :gin
    t.index ["archived"], name: "index_my_modules_on_archived"
    t.index ["archived_by_id"], name: "index_my_modules_on_archived_by_id"
    t.index ["created_by_id"], name: "index_my_modules_on_created_by_id"
    t.index ["experiment_id"], name: "index_my_modules_on_experiment_id"
    t.index ["last_modified_by_id"], name: "index_my_modules_on_last_modified_by_id"
    t.index ["my_module_group_id"], name: "index_my_modules_on_my_module_group_id"
    t.index ["my_module_status_id"], name: "index_my_modules_on_my_module_status_id"
    t.index ["restored_by_id"], name: "index_my_modules_on_restored_by_id"
  end

  create_table "notifications", force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.jsonb "params", default: {}, null: false
    t.string "type", null: false
    t.datetime "read_at"
    t.string "recipient_type"
    t.bigint "recipient_id"
    t.index ["created_at"], name: "index_notifications_on_created_at"
    t.index ["recipient_type", "recipient_id"], name: "index_notifications_on_recipient"
  end

  create_table "oauth_access_grants", force: :cascade do |t|
    t.bigint "resource_owner_id", null: false
    t.bigint "application_id", null: false
    t.string "token", null: false
    t.integer "expires_in", null: false
    t.text "redirect_uri", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "revoked_at", precision: nil
    t.string "scopes", default: "", null: false
    t.index ["application_id"], name: "index_oauth_access_grants_on_application_id"
    t.index ["token"], name: "index_oauth_access_grants_on_token", unique: true
  end

  create_table "oauth_access_tokens", force: :cascade do |t|
    t.bigint "resource_owner_id"
    t.bigint "application_id"
    t.text "token", null: false
    t.string "refresh_token"
    t.integer "expires_in"
    t.datetime "revoked_at", precision: nil
    t.datetime "created_at", precision: nil, null: false
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
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["uid"], name: "index_oauth_applications_on_uid", unique: true
  end

  create_table "project_folders", force: :cascade do |t|
    t.string "name", null: false
    t.bigint "team_id", null: false
    t.bigint "parent_folder_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "archived", default: false
    t.bigint "archived_by_id"
    t.datetime "archived_on", precision: nil
    t.bigint "restored_by_id"
    t.datetime "restored_on", precision: nil
    t.index "trim_html_tags((name)::text) gin_trgm_ops", name: "index_project_folders_on_name", using: :gin
    t.index ["archived"], name: "index_project_folders_on_archived"
    t.index ["parent_folder_id"], name: "index_project_folders_on_parent_folder_id"
    t.index ["team_id"], name: "index_project_folders_on_team_id"
  end

  create_table "projects", force: :cascade do |t|
    t.string "name", null: false
    t.integer "visibility", default: 0, null: false
    t.datetime "due_date", precision: nil
    t.bigint "team_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "archived", default: false, null: false
    t.datetime "archived_on", precision: nil
    t.bigint "created_by_id"
    t.bigint "last_modified_by_id"
    t.bigint "archived_by_id"
    t.bigint "restored_by_id"
    t.datetime "restored_on", precision: nil
    t.string "experiments_order"
    t.boolean "template"
    t.boolean "demo", default: false, null: false
    t.bigint "project_folder_id"
    t.bigint "default_public_user_role_id"
    t.index "(('PR'::text || id)) gin_trgm_ops", name: "index_projects_on_project_code", using: :gin
    t.index "trim_html_tags((name)::text) gin_trgm_ops", name: "index_projects_on_name", using: :gin
    t.index ["archived"], name: "index_projects_on_archived"
    t.index ["archived_by_id"], name: "index_projects_on_archived_by_id"
    t.index ["created_by_id"], name: "index_projects_on_created_by_id"
    t.index ["default_public_user_role_id"], name: "index_projects_on_default_public_user_role_id"
    t.index ["last_modified_by_id"], name: "index_projects_on_last_modified_by_id"
    t.index ["project_folder_id"], name: "index_projects_on_project_folder_id"
    t.index ["restored_by_id"], name: "index_projects_on_restored_by_id"
    t.index ["team_id"], name: "index_projects_on_team_id"
  end

  create_table "protocol_keywords", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "nr_of_protocols", default: 0
    t.bigint "team_id", null: false
    t.index "trim_html_tags((name)::text) gin_trgm_ops", name: "index_protocol_keywords_on_name", using: :gin
    t.index ["team_id"], name: "index_protocol_keywords_on_team_id"
  end

  create_table "protocol_protocol_keywords", force: :cascade do |t|
    t.bigint "protocol_id", null: false
    t.bigint "protocol_keyword_id", null: false
    t.index ["protocol_id"], name: "index_protocol_protocol_keywords_on_protocol_id"
    t.index ["protocol_keyword_id"], name: "index_protocol_protocol_keywords_on_protocol_keyword_id"
  end

  create_table "protocols", force: :cascade do |t|
    t.string "name"
    t.text "authors"
    t.text "description"
    t.bigint "added_by_id"
    t.bigint "my_module_id"
    t.bigint "team_id", null: false
    t.integer "protocol_type", default: 0, null: false
    t.bigint "parent_id"
    t.datetime "parent_updated_at", precision: nil
    t.bigint "archived_by_id"
    t.datetime "archived_on", precision: nil
    t.bigint "restored_by_id"
    t.datetime "restored_on", precision: nil
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "published_on", precision: nil
    t.integer "nr_of_linked_children", default: 0
    t.integer "visibility", default: 0
    t.boolean "archived", default: false, null: false
    t.integer "version_number", default: 1
    t.string "version_comment"
    t.bigint "default_public_user_role_id"
    t.bigint "previous_version_id"
    t.bigint "last_modified_by_id"
    t.bigint "published_by_id"
    t.datetime "linked_at", precision: nil
    t.index "(('PT'::text || id)) gin_trgm_ops", name: "index_protocols_on_protocol_code", using: :gin
    t.index "trim_html_tags((name)::text) gin_trgm_ops", name: "index_protocols_on_name", using: :gin
    t.index "trim_html_tags(authors) gin_trgm_ops", name: "index_protocols_on_authors", using: :gin
    t.index "trim_html_tags(description) gin_trgm_ops", name: "index_protocols_on_description", using: :gin
    t.index ["added_by_id"], name: "index_protocols_on_added_by_id"
    t.index ["archived"], name: "index_protocols_on_archived"
    t.index ["archived_by_id"], name: "index_protocols_on_archived_by_id"
    t.index ["default_public_user_role_id"], name: "index_protocols_on_default_public_user_role_id"
    t.index ["last_modified_by_id"], name: "index_protocols_on_last_modified_by_id"
    t.index ["my_module_id"], name: "index_protocols_on_my_module_id"
    t.index ["parent_id"], name: "index_protocols_on_parent_id"
    t.index ["previous_version_id"], name: "index_protocols_on_previous_version_id"
    t.index ["protocol_type"], name: "index_protocols_on_protocol_type"
    t.index ["published_by_id"], name: "index_protocols_on_published_by_id"
    t.index ["restored_by_id"], name: "index_protocols_on_restored_by_id"
    t.index ["team_id"], name: "index_protocols_on_team_id"
    t.index ["visibility"], name: "index_protocols_on_visibility"
  end

  create_table "report_elements", force: :cascade do |t|
    t.integer "position", null: false
    t.integer "type_of", null: false
    t.integer "sort_order", default: 0
    t.bigint "report_id"
    t.integer "parent_id"
    t.bigint "project_id"
    t.bigint "my_module_id"
    t.bigint "step_id"
    t.bigint "result_id"
    t.bigint "checklist_id"
    t.bigint "asset_id"
    t.bigint "table_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.bigint "experiment_id"
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

  create_table "report_template_values", force: :cascade do |t|
    t.bigint "report_id", null: false
    t.string "view_component", null: false
    t.string "name", null: false
    t.jsonb "value", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["report_id"], name: "index_report_template_values_on_report_id"
    t.index ["view_component", "name"], name: "index_report_template_values_on_view_component_name"
  end

  create_table "reports", force: :cascade do |t|
    t.string "name", null: false
    t.string "description"
    t.bigint "project_id", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.bigint "last_modified_by_id"
    t.bigint "team_id"
    t.integer "pdf_file_status", default: 0
    t.integer "docx_file_status", default: 0
    t.jsonb "settings", default: {}, null: false
    t.index "(('RP'::text || id)) gin_trgm_ops", name: "index_reports_on_report_code", using: :gin
    t.index "trim_html_tags((description)::text) gin_trgm_ops", name: "index_reports_on_description", using: :gin
    t.index "trim_html_tags((name)::text) gin_trgm_ops", name: "index_reports_on_name", using: :gin
    t.index ["last_modified_by_id"], name: "index_reports_on_last_modified_by_id"
    t.index ["project_id"], name: "index_reports_on_project_id"
    t.index ["team_id"], name: "index_reports_on_team_id"
    t.index ["user_id"], name: "index_reports_on_user_id"
  end

  create_table "repositories", force: :cascade do |t|
    t.integer "team_id"
    t.bigint "created_by_id", null: false
    t.string "name"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.datetime "discarded_at", precision: nil
    t.integer "permission_level", default: 0, null: false
    t.string "type"
    t.bigint "parent_id"
    t.integer "status"
    t.boolean "selected"
    t.bigint "my_module_id"
    t.boolean "archived", default: false, null: false
    t.datetime "archived_on", precision: nil
    t.datetime "restored_on", precision: nil
    t.bigint "archived_by_id"
    t.bigint "restored_by_id"
    t.index ["archived"], name: "index_repositories_on_archived"
    t.index ["archived_by_id"], name: "index_repositories_on_archived_by_id"
    t.index ["discarded_at"], name: "index_repositories_on_discarded_at"
    t.index ["my_module_id"], name: "index_repositories_on_my_module_id"
    t.index ["restored_by_id"], name: "index_repositories_on_restored_by_id"
    t.index ["team_id"], name: "index_repositories_on_team_id"
  end

  create_table "repository_asset_values", force: :cascade do |t|
    t.bigint "asset_id"
    t.bigint "created_by_id"
    t.bigint "last_modified_by_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["asset_id"], name: "index_repository_asset_values_on_asset_id"
    t.index ["created_by_id"], name: "index_repository_asset_values_on_created_by_id"
    t.index ["last_modified_by_id"], name: "index_repository_asset_values_on_last_modified_by_id"
  end

  create_table "repository_cells", force: :cascade do |t|
    t.bigint "repository_row_id"
    t.integer "repository_column_id"
    t.string "value_type"
    t.bigint "value_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["repository_column_id"], name: "index_repository_cells_on_repository_column_id"
    t.index ["repository_row_id", "repository_column_id"], name: "index_repository_cells_on_repository_row_and_repository_column", unique: true
    t.index ["repository_row_id"], name: "index_repository_cells_on_repository_row_id"
    t.index ["value_type", "value_id"], name: "index_repository_cells_on_value_type_and_value_id"
  end

  create_table "repository_checklist_items", force: :cascade do |t|
    t.string "data", null: false
    t.bigint "repository_column_id", null: false
    t.bigint "created_by_id"
    t.bigint "last_modified_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "external_id"
    t.index "trim_html_tags((data)::text) gin_trgm_ops", name: "index_repository_checklist_items_on_data", using: :gin
    t.index "trim_html_tags((external_id)::text) gin_trgm_ops", name: "index_repository_checklist_items_on_external_id", using: :gin
    t.index ["created_by_id"], name: "index_repository_checklist_items_on_created_by_id"
    t.index ["last_modified_by_id"], name: "index_repository_checklist_items_on_last_modified_by_id"
    t.index ["repository_column_id", "external_id"], name: "unique_index_repository_checklist_items_on_external_id", unique: true
    t.index ["repository_column_id"], name: "index_repository_checklist_items_on_repository_column_id"
  end

  create_table "repository_checklist_items_values", force: :cascade do |t|
    t.bigint "repository_checklist_value_id"
    t.bigint "repository_checklist_item_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["repository_checklist_item_id"], name: "index_on_repository_checklist_item_id"
    t.index ["repository_checklist_value_id"], name: "index_on_repository_checklist_value_id"
  end

  create_table "repository_checklist_values", force: :cascade do |t|
    t.bigint "created_by_id"
    t.bigint "last_modified_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_repository_checklist_values_on_created_by_id"
    t.index ["last_modified_by_id"], name: "index_repository_checklist_values_on_last_modified_by_id"
  end

  create_table "repository_columns", force: :cascade do |t|
    t.integer "repository_id"
    t.bigint "created_by_id", null: false
    t.string "name"
    t.integer "data_type", null: false
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.jsonb "metadata", default: {}, null: false
    t.bigint "parent_id"
    t.index ["repository_id"], name: "index_repository_columns_on_repository_id"
  end

  create_table "repository_date_time_range_values", force: :cascade do |t|
    t.datetime "start_time", precision: nil
    t.datetime "end_time", precision: nil
    t.bigint "last_modified_by_id"
    t.bigint "created_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "type"
    t.datetime "start_time_dup"
    t.datetime "end_time_dup"
    t.index "((end_time)::date)", name: "index_repository_date_time_range_values_on_end_time_as_date", where: "((type)::text = 'RepositoryDateRangeValue'::text)"
    t.index "((end_time)::time without time zone)", name: "index_repository_date_time_range_values_on_end_time_as_time", where: "((type)::text = 'RepositoryTimeRangeValue'::text)"
    t.index "((start_time)::date)", name: "index_repository_date_time_range_values_on_start_time_as_date", where: "((type)::text = 'RepositoryDateRangeValue'::text)"
    t.index "((start_time)::time without time zone)", name: "index_repository_date_time_range_values_on_start_time_as_time", where: "((type)::text = 'RepositoryTimeRangeValue'::text)"
    t.index ["created_by_id"], name: "index_repository_date_time_range_values_on_created_by_id"
    t.index ["end_time"], name: "index_repository_date_time_range_values_on_end_time_as_date_tim", where: "((type)::text = 'RepositoryDateTimeRangeValue'::text)"
    t.index ["last_modified_by_id"], name: "index_repository_date_time_range_values_on_last_modified_by_id"
    t.index ["start_time"], name: "index_repository_date_time_range_values_on_start_time_as_date_t", where: "((type)::text = 'RepositoryDateTimeRangeValue'::text)"
  end

  create_table "repository_date_time_values", force: :cascade do |t|
    t.datetime "data", precision: nil
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.bigint "created_by_id", null: false
    t.bigint "last_modified_by_id", null: false
    t.string "type"
    t.datetime "data_dup", precision: nil
    t.boolean "notification_sent", default: false
    t.index "((data)::date)", name: "index_repository_date_time_values_on_data_as_date", where: "((type)::text = 'RepositoryDateValue'::text)"
    t.index "((data)::time without time zone)", name: "index_repository_date_time_values_on_data_as_time", where: "((type)::text = 'RepositoryTimeValue'::text)"
    t.index ["data"], name: "index_repository_date_time_values_on_data_as_date_time", where: "((type)::text = 'RepositoryDateTimeValue'::text)"
  end

  create_table "repository_ledger_records", force: :cascade do |t|
    t.bigint "repository_stock_value_id", null: false
    t.string "reference_type", null: false
    t.bigint "reference_id", null: false
    t.decimal "amount"
    t.decimal "balance"
    t.bigint "user_id"
    t.text "comment"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "unit"
    t.jsonb "my_module_references"
    t.index ["reference_type", "reference_id"], name: "index_repository_ledger_records_on_reference"
    t.index ["repository_stock_value_id"], name: "index_repository_ledger_records_on_repository_stock_value_id"
    t.index ["user_id"], name: "index_repository_ledger_records_on_user_id"
  end

  create_table "repository_list_items", force: :cascade do |t|
    t.bigint "repository_column_id"
    t.text "data", null: false
    t.bigint "created_by_id"
    t.bigint "last_modified_by_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "external_id"
    t.index "trim_html_tags((external_id)::text) gin_trgm_ops", name: "index_repository_list_items_on_external_id", using: :gin
    t.index "trim_html_tags(data) gin_trgm_ops", name: "index_repository_list_items_on_data", using: :gin
    t.index ["created_by_id"], name: "index_repository_list_items_on_created_by_id"
    t.index ["last_modified_by_id"], name: "index_repository_list_items_on_last_modified_by_id"
    t.index ["repository_column_id", "external_id"], name: "unique_index_repository_list_items_on_external_id", unique: true
    t.index ["repository_column_id"], name: "index_repository_list_items_on_repository_column_id"
  end

  create_table "repository_list_values", force: :cascade do |t|
    t.bigint "repository_list_item_id"
    t.bigint "created_by_id"
    t.bigint "last_modified_by_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["created_by_id"], name: "index_repository_list_values_on_created_by_id"
    t.index ["last_modified_by_id"], name: "index_repository_list_values_on_last_modified_by_id"
    t.index ["repository_list_item_id"], name: "index_repository_list_values_on_repository_list_item_id"
  end

  create_table "repository_number_values", force: :cascade do |t|
    t.decimal "data"
    t.bigint "last_modified_by_id"
    t.bigint "created_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index "((data)::text) gin_trgm_ops", name: "index_repository_number_values_on_data_text", using: :gin
    t.index ["created_by_id"], name: "index_repository_number_values_on_created_by_id"
    t.index ["data"], name: "index_repository_number_values_on_data"
    t.index ["last_modified_by_id"], name: "index_repository_number_values_on_last_modified_by_id"
  end

  create_table "repository_rows", force: :cascade do |t|
    t.integer "repository_id"
    t.bigint "created_by_id", null: false
    t.bigint "last_modified_by_id", null: false
    t.string "name"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.bigint "parent_id"
    t.boolean "archived", default: false, null: false
    t.datetime "archived_on", precision: nil
    t.datetime "restored_on", precision: nil
    t.bigint "archived_by_id"
    t.bigint "restored_by_id"
    t.string "external_id"
    t.index "(('IT'::text || id)) gin_trgm_ops", name: "index_repository_rows_on_repository_row_code", using: :gin
    t.index "((id)::text) gin_trgm_ops", name: "index_repository_rows_on_id_text", using: :gin
    t.index "date_trunc('minute'::text, archived_on)", name: "index_repository_rows_on_archived_on_as_date_time_minutes"
    t.index "date_trunc('minute'::text, created_at)", name: "index_repository_rows_on_created_at_as_date_time_minutes"
    t.index "trim_html_tags((external_id)::text) gin_trgm_ops", name: "index_repository_rows_on_external_id", using: :gin
    t.index "trim_html_tags((name)::text) gin_trgm_ops", name: "index_repository_rows_on_name", using: :gin
    t.index ["archived"], name: "index_repository_rows_on_archived"
    t.index ["archived_by_id"], name: "index_repository_rows_on_archived_by_id"
    t.index ["repository_id", "external_id"], name: "unique_index_repository_rows_on_external_id", unique: true
    t.index ["repository_id"], name: "index_repository_rows_on_repository_id"
    t.index ["restored_by_id"], name: "index_repository_rows_on_restored_by_id"
  end

  create_table "repository_status_items", force: :cascade do |t|
    t.string "status", null: false
    t.string "icon", null: false
    t.bigint "repository_column_id", null: false
    t.bigint "created_by_id"
    t.bigint "last_modified_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index "trim_html_tags((status)::text) gin_trgm_ops", name: "index_repository_status_items_on_status", using: :gin
    t.index ["created_by_id"], name: "index_repository_status_items_on_created_by_id"
    t.index ["last_modified_by_id"], name: "index_repository_status_items_on_last_modified_by_id"
    t.index ["repository_column_id"], name: "index_repository_status_items_on_repository_column_id"
  end

  create_table "repository_status_values", force: :cascade do |t|
    t.bigint "created_by_id"
    t.bigint "last_modified_by_id"
    t.bigint "repository_status_item_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_repository_status_values_on_created_by_id"
    t.index ["last_modified_by_id"], name: "index_repository_status_values_on_last_modified_by_id"
    t.index ["repository_status_item_id"], name: "index_on_rep_status_type_id"
  end

  create_table "repository_stock_unit_items", force: :cascade do |t|
    t.string "data", null: false
    t.bigint "repository_column_id", null: false
    t.bigint "created_by_id"
    t.bigint "last_modified_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index "trim_html_tags((data)::text) gin_trgm_ops", name: "index_repository_stock_unit_items_on_data", using: :gin
    t.index ["created_by_id"], name: "index_repository_stock_unit_items_on_created_by_id"
    t.index ["last_modified_by_id"], name: "index_repository_stock_unit_items_on_last_modified_by_id"
    t.index ["repository_column_id"], name: "index_repository_stock_unit_items_on_repository_column_id"
  end

  create_table "repository_stock_values", force: :cascade do |t|
    t.decimal "amount"
    t.bigint "repository_stock_unit_item_id"
    t.string "type"
    t.bigint "last_modified_by_id"
    t.bigint "created_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "low_stock_threshold"
    t.index ["amount"], name: "index_repository_stock_values_on_amount"
    t.index ["created_by_id"], name: "index_repository_stock_values_on_created_by_id"
    t.index ["last_modified_by_id"], name: "index_repository_stock_values_on_last_modified_by_id"
    t.index ["repository_stock_unit_item_id"], name: "index_repository_stock_values_on_repository_stock_unit_item_id"
  end

  create_table "repository_table_filter_elements", force: :cascade do |t|
    t.bigint "repository_table_filter_id"
    t.bigint "repository_column_id"
    t.integer "operator"
    t.jsonb "parameters", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["repository_column_id"], name: "index_repository_table_filter_elements_on_repository_column_id"
    t.index ["repository_table_filter_id"], name: "index_on_repository_table_filter_id"
  end

  create_table "repository_table_filters", force: :cascade do |t|
    t.string "name", null: false
    t.jsonb "default_columns", default: {}, null: false
    t.bigint "repository_id"
    t.bigint "created_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_repository_table_filters_on_created_by_id"
    t.index ["repository_id"], name: "index_repository_table_filters_on_repository_id"
  end

  create_table "repository_table_states", force: :cascade do |t|
    t.jsonb "state", null: false
    t.integer "user_id", null: false
    t.integer "repository_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["repository_id"], name: "index_repository_table_states_on_repository_id"
    t.index ["user_id"], name: "index_repository_table_states_on_user_id"
  end

  create_table "repository_text_values", force: :cascade do |t|
    t.string "data"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.bigint "created_by_id", null: false
    t.bigint "last_modified_by_id", null: false
    t.index "trim_html_tags((data)::text) gin_trgm_ops", name: "index_repository_text_values_on_data", using: :gin
  end

  create_table "result_assets", force: :cascade do |t|
    t.bigint "result_id", null: false
    t.bigint "asset_id", null: false
    t.index ["result_id", "asset_id"], name: "index_result_assets_on_result_id_and_asset_id"
  end

  create_table "result_orderable_elements", force: :cascade do |t|
    t.bigint "result_id", null: false
    t.integer "position", null: false
    t.string "orderable_type"
    t.bigint "orderable_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["orderable_type", "orderable_id"], name: "index_result_orderable_elements_on_orderable"
    t.index ["result_id", "position"], name: "index_result_orderable_elements_on_result_id_and_position", unique: true
  end

  create_table "result_tables", force: :cascade do |t|
    t.bigint "result_id", null: false
    t.bigint "table_id", null: false
    t.index ["result_id", "table_id"], name: "index_result_tables_on_result_id_and_table_id"
  end

  create_table "result_texts", force: :cascade do |t|
    t.string "text"
    t.bigint "result_id", null: false
    t.string "name"
    t.index "trim_html_tags((text)::text) gin_trgm_ops", name: "index_result_texts_on_text", using: :gin
    t.index ["name"], name: "index_result_texts_on_name", opclass: :gist_trgm_ops, using: :gist
    t.index ["result_id"], name: "index_result_texts_on_result_id"
  end

  create_table "results", force: :cascade do |t|
    t.string "name"
    t.bigint "my_module_id", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "archived", default: false, null: false
    t.datetime "archived_on", precision: nil
    t.bigint "last_modified_by_id"
    t.bigint "archived_by_id"
    t.bigint "restored_by_id"
    t.datetime "restored_on", precision: nil
    t.integer "assets_view_mode", default: 0
    t.index "trim_html_tags((name)::text) gin_trgm_ops", name: "index_results_on_name", using: :gin
    t.index ["archived"], name: "index_results_on_archived"
    t.index ["archived_by_id"], name: "index_results_on_archived_by_id"
    t.index ["created_at"], name: "index_results_on_created_at"
    t.index ["last_modified_by_id"], name: "index_results_on_last_modified_by_id"
    t.index ["my_module_id"], name: "index_results_on_my_module_id"
    t.index ["restored_by_id"], name: "index_results_on_restored_by_id"
    t.index ["user_id"], name: "index_results_on_user_id"
  end

  create_table "settings", force: :cascade do |t|
    t.text "type", null: false
    t.jsonb "values", default: {}, null: false
    t.index ["type"], name: "index_settings_on_type", unique: true
  end

  create_table "shareable_links", force: :cascade do |t|
    t.string "uuid"
    t.string "description"
    t.string "shareable_type"
    t.bigint "shareable_id"
    t.bigint "team_id"
    t.bigint "created_by_id"
    t.bigint "last_modified_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_shareable_links_on_created_by_id"
    t.index ["last_modified_by_id"], name: "index_shareable_links_on_last_modified_by_id"
    t.index ["shareable_type", "shareable_id"], name: "index_shareable_links_on_shareable"
    t.index ["team_id"], name: "index_shareable_links_on_team_id"
    t.index ["uuid"], name: "index_shareable_links_on_uuid"
  end

  create_table "step_assets", force: :cascade do |t|
    t.bigint "step_id", null: false
    t.bigint "asset_id", null: false
    t.index ["step_id", "asset_id"], name: "index_step_assets_on_step_id_and_asset_id"
  end

  create_table "step_orderable_elements", force: :cascade do |t|
    t.bigint "step_id", null: false
    t.integer "position"
    t.string "orderable_type"
    t.bigint "orderable_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["orderable_type", "orderable_id"], name: "index_step_orderable_elements_on_orderable"
    t.index ["step_id"], name: "index_step_orderable_elements_on_step_id"
  end

  create_table "step_tables", force: :cascade do |t|
    t.bigint "step_id", null: false
    t.bigint "table_id", null: false
    t.index ["step_id", "table_id"], name: "index_step_tables_on_step_id_and_table_id", unique: true
  end

  create_table "step_texts", force: :cascade do |t|
    t.bigint "step_id", null: false
    t.string "text"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name"
    t.index "trim_html_tags((text)::text) gin_trgm_ops", name: "index_step_texts_on_text", using: :gin
    t.index ["name"], name: "index_step_texts_on_name", opclass: :gist_trgm_ops, using: :gist
    t.index ["step_id"], name: "index_step_texts_on_step_id"
  end

  create_table "steps", force: :cascade do |t|
    t.string "name"
    t.string "description"
    t.integer "position", null: false
    t.boolean "completed", null: false
    t.datetime "completed_on", precision: nil
    t.bigint "user_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.bigint "last_modified_by_id"
    t.bigint "protocol_id", null: false
    t.integer "assets_view_mode", default: 0, null: false
    t.index "trim_html_tags((description)::text) gin_trgm_ops", name: "index_steps_on_description", using: :gin
    t.index "trim_html_tags((name)::text) gin_trgm_ops", name: "index_steps_on_name", using: :gin
    t.index ["created_at"], name: "index_steps_on_created_at"
    t.index ["last_modified_by_id"], name: "index_steps_on_last_modified_by_id"
    t.index ["position"], name: "index_steps_on_position"
    t.index ["protocol_id"], name: "index_steps_on_protocol_id"
    t.index ["user_id"], name: "index_steps_on_user_id"
  end

  create_table "tables", force: :cascade do |t|
    t.binary "contents", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.bigint "created_by_id"
    t.bigint "last_modified_by_id"
    t.tsvector "data_vector"
    t.string "name", default: ""
    t.integer "team_id"
    t.jsonb "metadata"
    t.index "trim_html_tags((name)::text) gin_trgm_ops", name: "index_tables_on_name", using: :gin
    t.index ["created_at"], name: "index_tables_on_created_at"
    t.index ["created_by_id"], name: "index_tables_on_created_by_id"
    t.index ["data_vector"], name: "index_tables_on_data_vector", using: :gin
    t.index ["last_modified_by_id"], name: "index_tables_on_last_modified_by_id"
    t.index ["team_id"], name: "index_tables_on_team_id"
  end

  create_table "tags", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "color", default: "#ff0000", null: false
    t.bigint "project_id", null: false
    t.bigint "created_by_id"
    t.bigint "last_modified_by_id"
    t.index "trim_html_tags((name)::text) gin_trgm_ops", name: "index_tags_on_name", using: :gin
    t.index ["created_by_id"], name: "index_tags_on_created_by_id"
    t.index ["last_modified_by_id"], name: "index_tags_on_last_modified_by_id"
    t.index ["project_id"], name: "index_tags_on_project_id"
  end

  create_table "team_shared_objects", force: :cascade do |t|
    t.bigint "team_id"
    t.bigint "shared_object_id"
    t.integer "permission_level", default: 0, null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "shared_object_type"
    t.index ["shared_object_type", "shared_object_id", "team_id"], name: "index_team_shared_objects_on_shared_type_and_id_and_team_id", unique: true
    t.index ["team_id"], name: "index_team_shared_objects_on_team_id"
  end

  create_table "teams", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.bigint "created_by_id"
    t.bigint "last_modified_by_id"
    t.string "description"
    t.bigint "space_taken", default: 1048576, null: false
    t.boolean "shareable_links_enabled", default: false, null: false
    t.index ["created_by_id"], name: "index_teams_on_created_by_id"
    t.index ["last_modified_by_id"], name: "index_teams_on_last_modified_by_id"
    t.index ["name"], name: "index_teams_on_name"
  end

  create_table "temp_files", force: :cascade do |t|
    t.string "session_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "tiny_mce_assets", force: :cascade do |t|
    t.bigint "estimated_size", default: 0, null: false
    t.integer "team_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "saved", default: true
    t.string "object_type"
    t.bigint "object_id"
    t.index ["object_type", "object_id"], name: "index_tiny_mce_assets_on_object_type_and_object_id"
    t.index ["team_id"], name: "index_tiny_mce_assets_on_team_id"
  end

  create_table "tokens", force: :cascade do |t|
    t.string "token", null: false
    t.integer "ttl", null: false
    t.bigint "user_id", null: false
  end

  create_table "user_assignments", force: :cascade do |t|
    t.string "assignable_type", null: false
    t.bigint "assignable_id", null: false
    t.bigint "user_id", null: false
    t.bigint "user_role_id", null: false
    t.bigint "assigned_by_id"
    t.integer "assigned", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "team_id"
    t.index ["assignable_type", "assignable_id"], name: "index_user_assignments_on_assignable"
    t.index ["assigned_by_id"], name: "index_user_assignments_on_assigned_by_id"
    t.index ["team_id"], name: "index_user_assignments_on_team_id"
    t.index ["user_id"], name: "index_user_assignments_on_user_id"
    t.index ["user_role_id"], name: "index_user_assignments_on_user_role_id"
  end

  create_table "user_identities", force: :cascade do |t|
    t.integer "user_id"
    t.string "provider", null: false
    t.string "uid", null: false
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["provider", "uid"], name: "index_user_identities_on_provider_and_uid", unique: true
    t.index ["user_id", "provider"], name: "index_user_identities_on_user_id_and_provider", unique: true
    t.index ["user_id"], name: "index_user_identities_on_user_id"
  end

  create_table "user_my_modules", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "my_module_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.bigint "assigned_by_id"
    t.index ["assigned_by_id"], name: "index_user_my_modules_on_assigned_by_id"
    t.index ["my_module_id"], name: "index_user_my_modules_on_my_module_id"
    t.index ["user_id"], name: "index_user_my_modules_on_user_id"
  end

  create_table "user_projects", force: :cascade do |t|
    t.integer "role"
    t.bigint "user_id", null: false
    t.bigint "project_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.bigint "assigned_by_id"
    t.index ["assigned_by_id"], name: "index_user_projects_on_assigned_by_id"
    t.index ["project_id"], name: "index_user_projects_on_project_id"
    t.index ["user_id", "project_id"], name: "index_user_projects_on_user_id_and_project_id", unique: true
    t.index ["user_id"], name: "index_user_projects_on_user_id"
  end

  create_table "user_roles", force: :cascade do |t|
    t.string "name"
    t.boolean "predefined", default: false
    t.string "permissions", default: [], array: true
    t.bigint "created_by_id"
    t.bigint "last_modified_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_user_roles_on_created_by_id"
    t.index ["last_modified_by_id"], name: "index_user_roles_on_last_modified_by_id"
  end

  create_table "user_teams", force: :cascade do |t|
    t.integer "role", default: 1, null: false
    t.bigint "user_id", null: false
    t.bigint "team_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.bigint "assigned_by_id"
    t.index ["assigned_by_id"], name: "index_user_teams_on_assigned_by_id"
    t.index ["team_id"], name: "index_user_teams_on_team_id"
    t.index ["user_id", "team_id"], name: "index_user_teams_on_user_id_and_team_id", unique: true
    t.index ["user_id"], name: "index_user_teams_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "full_name", null: false
    t.string "initials", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at", precision: nil
    t.datetime "remember_created_at", precision: nil
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at", precision: nil
    t.datetime "last_sign_in_at", precision: nil
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "confirmation_token"
    t.datetime "confirmed_at", precision: nil
    t.datetime "confirmation_sent_at", precision: nil
    t.string "unconfirmed_email"
    t.string "invitation_token"
    t.datetime "invitation_created_at", precision: nil
    t.datetime "invitation_sent_at", precision: nil
    t.datetime "invitation_accepted_at", precision: nil
    t.integer "invitation_limit"
    t.string "invited_by_type"
    t.integer "invited_by_id"
    t.integer "invitations_count", default: 0
    t.bigint "current_team_id"
    t.string "authentication_token", limit: 30
    t.jsonb "settings", default: {}, null: false
    t.jsonb "variables", default: {}, null: false
    t.boolean "two_factor_auth_enabled", default: false, null: false
    t.string "otp_secret"
    t.jsonb "otp_recovery_codes"
    t.integer "failed_attempts", default: 0, null: false
    t.datetime "locked_at", precision: nil
    t.string "unlock_token"
    t.index "trim_html_tags((full_name)::text) gin_trgm_ops", name: "index_users_on_full_name", using: :gin
    t.index ["authentication_token"], name: "index_users_on_authentication_token", unique: true
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["invitation_token"], name: "index_users_on_invitation_token", unique: true
    t.index ["invitations_count"], name: "index_users_on_invitations_count"
    t.index ["invited_by_id"], name: "index_users_on_invited_by_id"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["unlock_token"], name: "index_users_on_unlock_token", unique: true
  end

  create_table "view_states", force: :cascade do |t|
    t.jsonb "state"
    t.bigint "user_id"
    t.string "viewable_type"
    t.bigint "viewable_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["user_id"], name: "index_view_states_on_user_id"
    t.index ["viewable_type", "viewable_id"], name: "index_view_states_on_viewable_type_and_viewable_id"
  end

  create_table "webhooks", force: :cascade do |t|
    t.bigint "activity_filter_id", null: false
    t.boolean "active", default: true, null: false
    t.string "url", null: false
    t.integer "http_method", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "last_error"
    t.text "text"
    t.string "secret_key"
    t.index ["activity_filter_id"], name: "index_webhooks_on_activity_filter_id"
  end

  create_table "wopi_actions", force: :cascade do |t|
    t.string "action", null: false
    t.string "extension", null: false
    t.string "urlsrc", null: false
    t.bigint "wopi_app_id", null: false
    t.index ["extension", "action"], name: "index_wopi_actions_on_extension_and_action"
  end

  create_table "wopi_apps", force: :cascade do |t|
    t.string "name", null: false
    t.string "icon", null: false
    t.bigint "wopi_discovery_id", null: false
  end

  create_table "wopi_discoveries", force: :cascade do |t|
    t.integer "expires", null: false
    t.string "proof_key_mod", null: false
    t.string "proof_key_exp", null: false
    t.string "proof_key_old_mod", null: false
    t.string "proof_key_old_exp", null: false
  end

  create_table "zip_exports", force: :cascade do |t|
    t.bigint "user_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "type"
    t.index ["user_id"], name: "index_zip_exports_on_user_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "activities", "experiments"
  add_foreign_key "activities", "my_modules"
  add_foreign_key "activities", "projects"
  add_foreign_key "activities", "users", column: "owner_id"
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
  add_foreign_key "connected_devices", "oauth_access_tokens"
  add_foreign_key "connections", "my_modules", column: "input_id"
  add_foreign_key "connections", "my_modules", column: "output_id"
  add_foreign_key "experiments", "users", column: "archived_by_id"
  add_foreign_key "experiments", "users", column: "created_by_id"
  add_foreign_key "experiments", "users", column: "last_modified_by_id"
  add_foreign_key "experiments", "users", column: "restored_by_id"
  add_foreign_key "hidden_repository_cell_reminders", "repository_cells"
  add_foreign_key "hidden_repository_cell_reminders", "users"
  add_foreign_key "label_templates", "teams"
  add_foreign_key "label_templates", "users", column: "created_by_id"
  add_foreign_key "label_templates", "users", column: "last_modified_by_id"
  add_foreign_key "my_module_groups", "experiments"
  add_foreign_key "my_module_groups", "users", column: "created_by_id"
  add_foreign_key "my_module_repository_rows", "repository_stock_unit_items"
  add_foreign_key "my_module_repository_rows", "users", column: "assigned_by_id"
  add_foreign_key "my_module_status_flows", "users", column: "created_by_id"
  add_foreign_key "my_module_status_flows", "users", column: "last_modified_by_id"
  add_foreign_key "my_module_statuses", "my_module_statuses", column: "previous_status_id"
  add_foreign_key "my_module_statuses", "users", column: "created_by_id"
  add_foreign_key "my_module_statuses", "users", column: "last_modified_by_id"
  add_foreign_key "my_module_tags", "users", column: "created_by_id"
  add_foreign_key "my_modules", "experiments"
  add_foreign_key "my_modules", "my_module_groups"
  add_foreign_key "my_modules", "my_module_statuses", column: "changing_from_my_module_status_id"
  add_foreign_key "my_modules", "users", column: "archived_by_id"
  add_foreign_key "my_modules", "users", column: "created_by_id"
  add_foreign_key "my_modules", "users", column: "last_modified_by_id"
  add_foreign_key "my_modules", "users", column: "restored_by_id"
  add_foreign_key "oauth_access_grants", "oauth_applications", column: "application_id"
  add_foreign_key "oauth_access_grants", "users", column: "resource_owner_id"
  add_foreign_key "oauth_access_tokens", "oauth_applications", column: "application_id"
  add_foreign_key "oauth_access_tokens", "users", column: "resource_owner_id"
  add_foreign_key "project_folders", "project_folders", column: "parent_folder_id"
  add_foreign_key "project_folders", "teams"
  add_foreign_key "project_folders", "users", column: "archived_by_id"
  add_foreign_key "project_folders", "users", column: "restored_by_id"
  add_foreign_key "projects", "project_folders"
  add_foreign_key "projects", "teams"
  add_foreign_key "projects", "user_roles", column: "default_public_user_role_id"
  add_foreign_key "projects", "users", column: "archived_by_id"
  add_foreign_key "projects", "users", column: "created_by_id"
  add_foreign_key "projects", "users", column: "last_modified_by_id"
  add_foreign_key "projects", "users", column: "restored_by_id"
  add_foreign_key "protocol_keywords", "teams"
  add_foreign_key "protocol_protocol_keywords", "protocol_keywords"
  add_foreign_key "protocol_protocol_keywords", "protocols"
  add_foreign_key "protocols", "my_modules"
  add_foreign_key "protocols", "protocols", column: "parent_id"
  add_foreign_key "protocols", "protocols", column: "previous_version_id"
  add_foreign_key "protocols", "teams"
  add_foreign_key "protocols", "user_roles", column: "default_public_user_role_id"
  add_foreign_key "protocols", "users", column: "added_by_id"
  add_foreign_key "protocols", "users", column: "archived_by_id"
  add_foreign_key "protocols", "users", column: "last_modified_by_id"
  add_foreign_key "protocols", "users", column: "published_by_id"
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
  add_foreign_key "report_template_values", "reports"
  add_foreign_key "reports", "projects"
  add_foreign_key "reports", "users"
  add_foreign_key "reports", "users", column: "last_modified_by_id"
  add_foreign_key "repositories", "users", column: "archived_by_id"
  add_foreign_key "repositories", "users", column: "created_by_id"
  add_foreign_key "repositories", "users", column: "restored_by_id"
  add_foreign_key "repository_asset_values", "users", column: "created_by_id"
  add_foreign_key "repository_asset_values", "users", column: "last_modified_by_id"
  add_foreign_key "repository_checklist_items", "repository_columns"
  add_foreign_key "repository_checklist_items", "users", column: "created_by_id"
  add_foreign_key "repository_checklist_items", "users", column: "last_modified_by_id"
  add_foreign_key "repository_checklist_values", "users", column: "created_by_id"
  add_foreign_key "repository_checklist_values", "users", column: "last_modified_by_id"
  add_foreign_key "repository_columns", "users", column: "created_by_id"
  add_foreign_key "repository_date_time_range_values", "users", column: "created_by_id"
  add_foreign_key "repository_date_time_range_values", "users", column: "last_modified_by_id"
  add_foreign_key "repository_date_time_values", "users", column: "created_by_id"
  add_foreign_key "repository_date_time_values", "users", column: "last_modified_by_id"
  add_foreign_key "repository_ledger_records", "repository_stock_values"
  add_foreign_key "repository_list_items", "repository_columns"
  add_foreign_key "repository_list_items", "users", column: "created_by_id"
  add_foreign_key "repository_list_items", "users", column: "last_modified_by_id"
  add_foreign_key "repository_list_values", "users", column: "created_by_id"
  add_foreign_key "repository_list_values", "users", column: "last_modified_by_id"
  add_foreign_key "repository_number_values", "users", column: "created_by_id"
  add_foreign_key "repository_number_values", "users", column: "last_modified_by_id"
  add_foreign_key "repository_rows", "users", column: "archived_by_id"
  add_foreign_key "repository_rows", "users", column: "created_by_id"
  add_foreign_key "repository_rows", "users", column: "last_modified_by_id"
  add_foreign_key "repository_rows", "users", column: "restored_by_id"
  add_foreign_key "repository_status_items", "repository_columns"
  add_foreign_key "repository_status_items", "users", column: "created_by_id"
  add_foreign_key "repository_status_items", "users", column: "last_modified_by_id"
  add_foreign_key "repository_status_values", "repository_status_items"
  add_foreign_key "repository_status_values", "users", column: "created_by_id"
  add_foreign_key "repository_status_values", "users", column: "last_modified_by_id"
  add_foreign_key "repository_stock_unit_items", "repository_columns"
  add_foreign_key "repository_stock_unit_items", "users", column: "created_by_id"
  add_foreign_key "repository_stock_unit_items", "users", column: "last_modified_by_id"
  add_foreign_key "repository_stock_values", "repository_stock_unit_items"
  add_foreign_key "repository_stock_values", "users", column: "created_by_id"
  add_foreign_key "repository_stock_values", "users", column: "last_modified_by_id"
  add_foreign_key "repository_table_filters", "users", column: "created_by_id"
  add_foreign_key "repository_text_values", "users", column: "created_by_id"
  add_foreign_key "repository_text_values", "users", column: "last_modified_by_id"
  add_foreign_key "result_assets", "assets"
  add_foreign_key "result_assets", "results"
  add_foreign_key "result_orderable_elements", "results"
  add_foreign_key "result_tables", "results"
  add_foreign_key "result_tables", "tables"
  add_foreign_key "result_texts", "results"
  add_foreign_key "results", "my_modules"
  add_foreign_key "results", "users"
  add_foreign_key "results", "users", column: "archived_by_id"
  add_foreign_key "results", "users", column: "last_modified_by_id"
  add_foreign_key "results", "users", column: "restored_by_id"
  add_foreign_key "shareable_links", "teams"
  add_foreign_key "shareable_links", "users", column: "created_by_id"
  add_foreign_key "shareable_links", "users", column: "last_modified_by_id"
  add_foreign_key "step_assets", "assets"
  add_foreign_key "step_assets", "steps"
  add_foreign_key "step_orderable_elements", "steps"
  add_foreign_key "step_tables", "steps"
  add_foreign_key "step_tables", "tables"
  add_foreign_key "step_texts", "steps"
  add_foreign_key "steps", "protocols"
  add_foreign_key "steps", "users"
  add_foreign_key "steps", "users", column: "last_modified_by_id"
  add_foreign_key "tables", "users", column: "created_by_id"
  add_foreign_key "tables", "users", column: "last_modified_by_id"
  add_foreign_key "tags", "projects"
  add_foreign_key "tags", "users", column: "created_by_id"
  add_foreign_key "tags", "users", column: "last_modified_by_id"
  add_foreign_key "team_shared_objects", "repositories", column: "shared_object_id"
  add_foreign_key "team_shared_objects", "teams"
  add_foreign_key "teams", "users", column: "created_by_id"
  add_foreign_key "teams", "users", column: "last_modified_by_id"
  add_foreign_key "tokens", "users"
  add_foreign_key "user_assignments", "teams"
  add_foreign_key "user_assignments", "user_roles"
  add_foreign_key "user_assignments", "users"
  add_foreign_key "user_assignments", "users", column: "assigned_by_id"
  add_foreign_key "user_my_modules", "my_modules"
  add_foreign_key "user_my_modules", "users"
  add_foreign_key "user_my_modules", "users", column: "assigned_by_id"
  add_foreign_key "user_projects", "projects"
  add_foreign_key "user_projects", "users"
  add_foreign_key "user_projects", "users", column: "assigned_by_id"
  add_foreign_key "user_roles", "users", column: "created_by_id"
  add_foreign_key "user_roles", "users", column: "last_modified_by_id"
  add_foreign_key "user_teams", "teams"
  add_foreign_key "user_teams", "users"
  add_foreign_key "user_teams", "users", column: "assigned_by_id"
  add_foreign_key "users", "teams", column: "current_team_id"
  add_foreign_key "view_states", "users"
  add_foreign_key "webhooks", "activity_filters"
  add_foreign_key "wopi_actions", "wopi_apps"
  add_foreign_key "wopi_apps", "wopi_discoveries"
  add_foreign_key "zip_exports", "users"
end
