# encoding: UTF-8
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

ActiveRecord::Schema.define(version: 20160809074757) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "pg_trgm"
  enable_extension "btree_gist"

  create_table "activities", force: :cascade do |t|
    t.integer  "my_module_id"
    t.integer  "user_id"
    t.integer  "type_of",      null: false
    t.string   "message",      null: false
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
    t.integer  "project_id",   null: false
  end

  add_index "activities", ["created_at"], name: "index_activities_on_created_at", using: :btree
  add_index "activities", ["my_module_id"], name: "index_activities_on_my_module_id", using: :btree
  add_index "activities", ["project_id"], name: "index_activities_on_project_id", using: :btree
  add_index "activities", ["type_of"], name: "index_activities_on_type_of", using: :btree
  add_index "activities", ["user_id"], name: "index_activities_on_user_id", using: :btree

  create_table "asset_text_data", force: :cascade do |t|
    t.text     "data",        null: false
    t.integer  "asset_id",    null: false
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
    t.tsvector "data_vector"
  end

  add_index "asset_text_data", ["asset_id"], name: "index_asset_text_data_on_asset_id", unique: true, using: :btree
  add_index "asset_text_data", ["data_vector"], name: "index_asset_text_data_on_data_vector", using: :gin

  create_table "assets", force: :cascade do |t|
    t.datetime "created_at",                                       null: false
    t.datetime "updated_at",                                       null: false
    t.string   "file_file_name"
    t.string   "file_content_type"
    t.integer  "file_file_size"
    t.datetime "file_updated_at"
    t.integer  "created_by_id"
    t.integer  "last_modified_by_id"
    t.integer  "estimated_size",                   default: 0,     null: false
    t.boolean  "file_present",                     default: false, null: false
    t.string   "lock",                limit: 1024
    t.integer  "lock_ttl"
    t.integer  "version",                          default: 1
  end

  add_index "assets", ["created_at"], name: "index_assets_on_created_at", using: :btree
  add_index "assets", ["created_by_id"], name: "index_assets_on_created_by_id", using: :btree
  add_index "assets", ["file_file_name"], name: "index_assets_on_file_file_name", using: :gist
  add_index "assets", ["last_modified_by_id"], name: "index_assets_on_last_modified_by_id", using: :btree

  create_table "checklist_items", force: :cascade do |t|
    t.string   "text",                                null: false
    t.boolean  "checked",             default: false, null: false
    t.integer  "checklist_id",                        null: false
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
    t.integer  "created_by_id"
    t.integer  "last_modified_by_id"
    t.integer  "position",            default: 0,     null: false
  end

  add_index "checklist_items", ["checklist_id"], name: "index_checklist_items_on_checklist_id", using: :btree
  add_index "checklist_items", ["created_by_id"], name: "index_checklist_items_on_created_by_id", using: :btree
  add_index "checklist_items", ["last_modified_by_id"], name: "index_checklist_items_on_last_modified_by_id", using: :btree

  create_table "checklists", force: :cascade do |t|
    t.string   "name",                null: false
    t.integer  "step_id",             null: false
    t.datetime "created_at",          null: false
    t.datetime "updated_at",          null: false
    t.integer  "created_by_id"
    t.integer  "last_modified_by_id"
  end

  add_index "checklists", ["created_by_id"], name: "index_checklists_on_created_by_id", using: :btree
  add_index "checklists", ["last_modified_by_id"], name: "index_checklists_on_last_modified_by_id", using: :btree

  create_table "comments", force: :cascade do |t|
    t.string   "message",             null: false
    t.integer  "user_id",             null: false
    t.datetime "created_at",          null: false
    t.datetime "updated_at",          null: false
    t.integer  "last_modified_by_id"
  end

  add_index "comments", ["created_at"], name: "index_comments_on_created_at", using: :btree
  add_index "comments", ["last_modified_by_id"], name: "index_comments_on_last_modified_by_id", using: :btree
  add_index "comments", ["user_id"], name: "index_comments_on_user_id", using: :btree

  create_table "connections", force: :cascade do |t|
    t.integer "input_id",  null: false
    t.integer "output_id", null: false
  end

  create_table "custom_fields", force: :cascade do |t|
    t.string   "name",                null: false
    t.integer  "user_id",             null: false
    t.integer  "organization_id",     null: false
    t.datetime "created_at",          null: false
    t.datetime "updated_at",          null: false
    t.integer  "last_modified_by_id"
  end

  add_index "custom_fields", ["last_modified_by_id"], name: "index_custom_fields_on_last_modified_by_id", using: :btree
  add_index "custom_fields", ["organization_id"], name: "index_custom_fields_on_organization_id", using: :btree
  add_index "custom_fields", ["user_id"], name: "index_custom_fields_on_user_id", using: :btree

  create_table "delayed_jobs", force: :cascade do |t|
    t.integer  "priority",   default: 0, null: false
    t.integer  "attempts",   default: 0, null: false
    t.text     "handler",                null: false
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.string   "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "delayed_jobs", ["priority", "run_at"], name: "delayed_jobs_priority", using: :btree
  add_index "delayed_jobs", ["queue"], name: "delayed_jobs_queue", using: :btree

  create_table "experiments", force: :cascade do |t|
    t.string   "name",                                     null: false
    t.text     "description"
    t.integer  "project_id",                               null: false
    t.integer  "created_by_id",                            null: false
    t.integer  "last_modified_by_id",                      null: false
    t.boolean  "archived",                 default: false, null: false
    t.integer  "archived_by_id"
    t.datetime "archived_on"
    t.integer  "restored_by_id"
    t.datetime "restored_on"
    t.datetime "created_at",                               null: false
    t.datetime "updated_at",                               null: false
    t.string   "workflowimg_file_name"
    t.string   "workflowimg_content_type"
    t.integer  "workflowimg_file_size"
    t.datetime "workflowimg_updated_at"
  end

  add_index "experiments", ["archived_by_id"], name: "index_experiments_on_archived_by_id", using: :btree
  add_index "experiments", ["created_by_id"], name: "index_experiments_on_created_by_id", using: :btree
  add_index "experiments", ["last_modified_by_id"], name: "index_experiments_on_last_modified_by_id", using: :btree
  add_index "experiments", ["name"], name: "index_experiments_on_name", using: :btree
  add_index "experiments", ["project_id"], name: "index_experiments_on_project_id", using: :btree
  add_index "experiments", ["restored_by_id"], name: "index_experiments_on_restored_by_id", using: :btree

  create_table "logs", force: :cascade do |t|
    t.integer "organization_id", null: false
    t.string  "message",         null: false
  end

  create_table "my_module_comments", force: :cascade do |t|
    t.integer "my_module_id", null: false
    t.integer "comment_id",   null: false
  end

  add_index "my_module_comments", ["my_module_id", "comment_id"], name: "index_my_module_comments_on_my_module_id_and_comment_id", using: :btree

  create_table "my_module_groups", force: :cascade do |t|
    t.string   "name",                      null: false
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
    t.integer  "created_by_id"
    t.integer  "experiment_id", default: 0, null: false
  end

  add_index "my_module_groups", ["created_by_id"], name: "index_my_module_groups_on_created_by_id", using: :btree
  add_index "my_module_groups", ["experiment_id"], name: "index_my_module_groups_on_experiment_id", using: :btree
  add_index "my_module_groups", ["name"], name: "index_my_module_groups_on_name", using: :gist

  create_table "my_module_tags", force: :cascade do |t|
    t.integer "my_module_id"
    t.integer "tag_id"
    t.integer "created_by_id"
  end

  add_index "my_module_tags", ["created_by_id"], name: "index_my_module_tags_on_created_by_id", using: :btree
  add_index "my_module_tags", ["my_module_id"], name: "index_my_module_tags_on_my_module_id", using: :btree
  add_index "my_module_tags", ["tag_id"], name: "index_my_module_tags_on_tag_id", using: :btree

  create_table "my_modules", force: :cascade do |t|
    t.string   "name",                                   null: false
    t.datetime "due_date"
    t.string   "description"
    t.integer  "x",                      default: 0,     null: false
    t.integer  "y",                      default: 0,     null: false
    t.integer  "my_module_group_id"
    t.datetime "created_at",                             null: false
    t.datetime "updated_at",                             null: false
    t.boolean  "archived",               default: false, null: false
    t.datetime "archived_on"
    t.integer  "created_by_id"
    t.integer  "last_modified_by_id"
    t.integer  "archived_by_id"
    t.integer  "restored_by_id"
    t.datetime "restored_on"
    t.integer  "nr_of_assigned_samples", default: 0
    t.integer  "workflow_order",         default: -1,    null: false
    t.integer  "experiment_id",          default: 0,     null: false
  end

  add_index "my_modules", ["archived_by_id"], name: "index_my_modules_on_archived_by_id", using: :btree
  add_index "my_modules", ["created_by_id"], name: "index_my_modules_on_created_by_id", using: :btree
  add_index "my_modules", ["experiment_id"], name: "index_my_modules_on_experiment_id", using: :btree
  add_index "my_modules", ["last_modified_by_id"], name: "index_my_modules_on_last_modified_by_id", using: :btree
  add_index "my_modules", ["my_module_group_id"], name: "index_my_modules_on_my_module_group_id", using: :btree
  add_index "my_modules", ["name"], name: "index_my_modules_on_name", using: :gist
  add_index "my_modules", ["restored_by_id"], name: "index_my_modules_on_restored_by_id", using: :btree

  create_table "organizations", force: :cascade do |t|
    t.string   "name",                                            null: false
    t.datetime "created_at",                                      null: false
    t.datetime "updated_at",                                      null: false
    t.integer  "created_by_id"
    t.integer  "last_modified_by_id"
    t.string   "description"
    t.integer  "space_taken",         limit: 8, default: 1048576, null: false
  end

  add_index "organizations", ["created_by_id"], name: "index_organizations_on_created_by_id", using: :btree
  add_index "organizations", ["last_modified_by_id"], name: "index_organizations_on_last_modified_by_id", using: :btree
  add_index "organizations", ["name"], name: "index_organizations_on_name", using: :btree

  create_table "project_comments", force: :cascade do |t|
    t.integer "project_id", null: false
    t.integer "comment_id", null: false
  end

  add_index "project_comments", ["project_id", "comment_id"], name: "index_project_comments_on_project_id_and_comment_id", using: :btree

  create_table "projects", force: :cascade do |t|
    t.string   "name",                                null: false
    t.integer  "visibility",          default: 0,     null: false
    t.datetime "due_date"
    t.integer  "organization_id",                     null: false
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
    t.boolean  "archived",            default: false, null: false
    t.datetime "archived_on"
    t.integer  "created_by_id"
    t.integer  "last_modified_by_id"
    t.integer  "archived_by_id"
    t.integer  "restored_by_id"
    t.datetime "restored_on"
  end

  add_index "projects", ["archived_by_id"], name: "index_projects_on_archived_by_id", using: :btree
  add_index "projects", ["created_by_id"], name: "index_projects_on_created_by_id", using: :btree
  add_index "projects", ["last_modified_by_id"], name: "index_projects_on_last_modified_by_id", using: :btree
  add_index "projects", ["name"], name: "index_projects_on_name", using: :gist
  add_index "projects", ["organization_id"], name: "index_projects_on_organization_id", using: :btree
  add_index "projects", ["restored_by_id"], name: "index_projects_on_restored_by_id", using: :btree

  create_table "protocol_keywords", force: :cascade do |t|
    t.string   "name"
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
    t.integer  "nr_of_protocols", default: 0
    t.integer  "organization_id",             null: false
  end

  add_index "protocol_keywords", ["name"], name: "index_protocol_keywords_on_name", using: :btree
  add_index "protocol_keywords", ["organization_id"], name: "index_protocol_keywords_on_organization_id", using: :btree

  create_table "protocol_protocol_keywords", force: :cascade do |t|
    t.integer "protocol_id",         null: false
    t.integer "protocol_keyword_id", null: false
  end

  add_index "protocol_protocol_keywords", ["protocol_id"], name: "index_protocol_protocol_keywords_on_protocol_id", using: :btree
  add_index "protocol_protocol_keywords", ["protocol_keyword_id"], name: "index_protocol_protocol_keywords_on_protocol_keyword_id", using: :btree

  create_table "protocols", force: :cascade do |t|
    t.string   "name"
    t.text     "authors"
    t.text     "description"
    t.integer  "added_by_id"
    t.integer  "my_module_id"
    t.integer  "organization_id",                   null: false
    t.integer  "protocol_type",         default: 0, null: false
    t.integer  "parent_id"
    t.datetime "parent_updated_at"
    t.integer  "archived_by_id"
    t.datetime "archived_on"
    t.integer  "restored_by_id"
    t.datetime "restored_on"
    t.datetime "created_at",                        null: false
    t.datetime "updated_at",                        null: false
    t.datetime "published_on"
    t.integer  "nr_of_linked_children", default: 0
  end

  add_index "protocols", ["added_by_id"], name: "index_protocols_on_added_by_id", using: :btree
  add_index "protocols", ["archived_by_id"], name: "index_protocols_on_archived_by_id", using: :btree
  add_index "protocols", ["authors"], name: "index_protocols_on_authors", using: :btree
  add_index "protocols", ["description"], name: "index_protocols_on_description", using: :btree
  add_index "protocols", ["my_module_id"], name: "index_protocols_on_my_module_id", using: :btree
  add_index "protocols", ["name"], name: "index_protocols_on_name", using: :btree
  add_index "protocols", ["organization_id"], name: "index_protocols_on_organization_id", using: :btree
  add_index "protocols", ["parent_id"], name: "index_protocols_on_parent_id", using: :btree
  add_index "protocols", ["restored_by_id"], name: "index_protocols_on_restored_by_id", using: :btree

  create_table "report_elements", force: :cascade do |t|
    t.integer  "position",                  null: false
    t.integer  "type_of",                   null: false
    t.integer  "sort_order",    default: 0
    t.integer  "report_id"
    t.integer  "parent_id"
    t.integer  "project_id"
    t.integer  "my_module_id"
    t.integer  "step_id"
    t.integer  "result_id"
    t.integer  "checklist_id"
    t.integer  "asset_id"
    t.integer  "table_id"
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
    t.integer  "experiment_id"
  end

  add_index "report_elements", ["asset_id"], name: "index_report_elements_on_asset_id", using: :btree
  add_index "report_elements", ["checklist_id"], name: "index_report_elements_on_checklist_id", using: :btree
  add_index "report_elements", ["experiment_id"], name: "index_report_elements_on_experiment_id", using: :btree
  add_index "report_elements", ["my_module_id"], name: "index_report_elements_on_my_module_id", using: :btree
  add_index "report_elements", ["parent_id"], name: "index_report_elements_on_parent_id", using: :btree
  add_index "report_elements", ["project_id"], name: "index_report_elements_on_project_id", using: :btree
  add_index "report_elements", ["report_id"], name: "index_report_elements_on_report_id", using: :btree
  add_index "report_elements", ["result_id"], name: "index_report_elements_on_result_id", using: :btree
  add_index "report_elements", ["step_id"], name: "index_report_elements_on_step_id", using: :btree
  add_index "report_elements", ["table_id"], name: "index_report_elements_on_table_id", using: :btree

  create_table "reports", force: :cascade do |t|
    t.string   "name",                null: false
    t.string   "description"
    t.integer  "project_id",          null: false
    t.integer  "user_id",             null: false
    t.datetime "created_at",          null: false
    t.datetime "updated_at",          null: false
    t.integer  "last_modified_by_id"
  end

  add_index "reports", ["last_modified_by_id"], name: "index_reports_on_last_modified_by_id", using: :btree
  add_index "reports", ["project_id"], name: "index_reports_on_project_id", using: :btree
  add_index "reports", ["user_id"], name: "index_reports_on_user_id", using: :btree

  create_table "result_assets", force: :cascade do |t|
    t.integer "result_id", null: false
    t.integer "asset_id",  null: false
  end

  add_index "result_assets", ["result_id", "asset_id"], name: "index_result_assets_on_result_id_and_asset_id", using: :btree

  create_table "result_comments", force: :cascade do |t|
    t.integer "result_id",  null: false
    t.integer "comment_id", null: false
  end

  add_index "result_comments", ["result_id", "comment_id"], name: "index_result_comments_on_result_id_and_comment_id", using: :btree

  create_table "result_tables", force: :cascade do |t|
    t.integer "result_id", null: false
    t.integer "table_id",  null: false
  end

  add_index "result_tables", ["result_id", "table_id"], name: "index_result_tables_on_result_id_and_table_id", using: :btree

  create_table "result_texts", force: :cascade do |t|
    t.string  "text",      null: false
    t.integer "result_id", null: false
  end

  add_index "result_texts", ["result_id"], name: "index_result_texts_on_result_id", using: :btree

  create_table "results", force: :cascade do |t|
    t.string   "name"
    t.integer  "my_module_id",                        null: false
    t.integer  "user_id",                             null: false
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
    t.boolean  "archived",            default: false, null: false
    t.datetime "archived_on"
    t.integer  "last_modified_by_id"
    t.integer  "archived_by_id"
    t.integer  "restored_by_id"
    t.datetime "restored_on"
  end

  add_index "results", ["archived_by_id"], name: "index_results_on_archived_by_id", using: :btree
  add_index "results", ["created_at"], name: "index_results_on_created_at", using: :btree
  add_index "results", ["last_modified_by_id"], name: "index_results_on_last_modified_by_id", using: :btree
  add_index "results", ["my_module_id"], name: "index_results_on_my_module_id", using: :btree
  add_index "results", ["name"], name: "index_results_on_name", using: :gist
  add_index "results", ["restored_by_id"], name: "index_results_on_restored_by_id", using: :btree
  add_index "results", ["user_id"], name: "index_results_on_user_id", using: :btree

  create_table "sample_comments", force: :cascade do |t|
    t.integer "sample_id",  null: false
    t.integer "comment_id", null: false
  end

  add_index "sample_comments", ["sample_id", "comment_id"], name: "index_sample_comments_on_sample_id_and_comment_id", using: :btree

  create_table "sample_custom_fields", force: :cascade do |t|
    t.string   "value",           null: false
    t.integer  "custom_field_id", null: false
    t.integer  "sample_id"
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
  end

  add_index "sample_custom_fields", ["custom_field_id"], name: "index_sample_custom_fields_on_custom_field_id", using: :btree
  add_index "sample_custom_fields", ["sample_id"], name: "index_sample_custom_fields_on_sample_id", using: :btree

  create_table "sample_groups", force: :cascade do |t|
    t.string   "name",                                    null: false
    t.string   "color",               default: "#ff0000", null: false
    t.integer  "organization_id",                         null: false
    t.datetime "created_at",                              null: false
    t.datetime "updated_at",                              null: false
    t.integer  "created_by_id"
    t.integer  "last_modified_by_id"
  end

  add_index "sample_groups", ["created_by_id"], name: "index_sample_groups_on_created_by_id", using: :btree
  add_index "sample_groups", ["last_modified_by_id"], name: "index_sample_groups_on_last_modified_by_id", using: :btree
  add_index "sample_groups", ["organization_id"], name: "index_sample_groups_on_organization_id", using: :btree

  create_table "sample_my_modules", force: :cascade do |t|
    t.integer  "sample_id",      null: false
    t.integer  "my_module_id",   null: false
    t.integer  "assigned_by_id"
    t.datetime "assigned_on"
  end

  add_index "sample_my_modules", ["assigned_by_id"], name: "index_sample_my_modules_on_assigned_by_id", using: :btree
  add_index "sample_my_modules", ["sample_id", "my_module_id"], name: "index_sample_my_modules_on_sample_id_and_my_module_id", using: :btree

  create_table "sample_types", force: :cascade do |t|
    t.string   "name",                null: false
    t.integer  "organization_id",     null: false
    t.datetime "created_at",          null: false
    t.datetime "updated_at",          null: false
    t.integer  "created_by_id"
    t.integer  "last_modified_by_id"
  end

  add_index "sample_types", ["created_by_id"], name: "index_sample_types_on_created_by_id", using: :btree
  add_index "sample_types", ["last_modified_by_id"], name: "index_sample_types_on_last_modified_by_id", using: :btree
  add_index "sample_types", ["organization_id"], name: "index_sample_types_on_organization_id", using: :btree

  create_table "samples", force: :cascade do |t|
    t.string   "name",                                  null: false
    t.integer  "user_id",                               null: false
    t.integer  "organization_id",                       null: false
    t.datetime "created_at",                            null: false
    t.datetime "updated_at",                            null: false
    t.integer  "sample_group_id"
    t.integer  "sample_type_id"
    t.integer  "last_modified_by_id"
    t.integer  "nr_of_modules_assigned_to", default: 0
  end

  add_index "samples", ["last_modified_by_id"], name: "index_samples_on_last_modified_by_id", using: :btree
  add_index "samples", ["name"], name: "index_samples_on_name", using: :gist
  add_index "samples", ["organization_id"], name: "index_samples_on_organization_id", using: :btree
  add_index "samples", ["sample_group_id"], name: "index_samples_on_sample_group_id", using: :btree
  add_index "samples", ["sample_type_id"], name: "index_samples_on_sample_type_id", using: :btree
  add_index "samples", ["user_id"], name: "index_samples_on_user_id", using: :btree

  create_table "step_assets", force: :cascade do |t|
    t.integer "step_id",  null: false
    t.integer "asset_id", null: false
  end

  add_index "step_assets", ["step_id", "asset_id"], name: "index_step_assets_on_step_id_and_asset_id", using: :btree

  create_table "step_comments", force: :cascade do |t|
    t.integer "step_id",    null: false
    t.integer "comment_id", null: false
  end

  add_index "step_comments", ["step_id", "comment_id"], name: "index_step_comments_on_step_id_and_comment_id", using: :btree

  create_table "step_tables", force: :cascade do |t|
    t.integer "step_id",  null: false
    t.integer "table_id", null: false
  end

  add_index "step_tables", ["step_id", "table_id"], name: "index_step_tables_on_step_id_and_table_id", unique: true, using: :btree

  create_table "steps", force: :cascade do |t|
    t.string   "name"
    t.string   "description"
    t.integer  "position",            null: false
    t.boolean  "completed",           null: false
    t.datetime "completed_on"
    t.integer  "user_id",             null: false
    t.datetime "created_at",          null: false
    t.datetime "updated_at",          null: false
    t.integer  "last_modified_by_id"
    t.integer  "protocol_id",         null: false
  end

  add_index "steps", ["created_at"], name: "index_steps_on_created_at", using: :btree
  add_index "steps", ["last_modified_by_id"], name: "index_steps_on_last_modified_by_id", using: :btree
  add_index "steps", ["name"], name: "index_steps_on_name", using: :gist
  add_index "steps", ["position"], name: "index_steps_on_position", using: :btree
  add_index "steps", ["protocol_id"], name: "index_steps_on_protocol_id", using: :btree
  add_index "steps", ["user_id"], name: "index_steps_on_user_id", using: :btree

  create_table "tables", force: :cascade do |t|
    t.binary   "contents",            null: false
    t.datetime "created_at",          null: false
    t.datetime "updated_at",          null: false
    t.integer  "created_by_id"
    t.integer  "last_modified_by_id"
    t.tsvector "data_vector"
  end

  add_index "tables", ["created_at"], name: "index_tables_on_created_at", using: :btree
  add_index "tables", ["created_by_id"], name: "index_tables_on_created_by_id", using: :btree
  add_index "tables", ["data_vector"], name: "index_tables_on_data_vector", using: :gin
  add_index "tables", ["last_modified_by_id"], name: "index_tables_on_last_modified_by_id", using: :btree

  create_table "tags", force: :cascade do |t|
    t.string   "name",                                    null: false
    t.datetime "created_at",                              null: false
    t.datetime "updated_at",                              null: false
    t.string   "color",               default: "#ff0000", null: false
    t.integer  "project_id",                              null: false
    t.integer  "created_by_id"
    t.integer  "last_modified_by_id"
  end

  add_index "tags", ["created_by_id"], name: "index_tags_on_created_by_id", using: :btree
  add_index "tags", ["last_modified_by_id"], name: "index_tags_on_last_modified_by_id", using: :btree
  add_index "tags", ["name"], name: "index_tags_on_name", using: :gist
  add_index "tags", ["project_id"], name: "index_tags_on_project_id", using: :btree

  create_table "temp_files", force: :cascade do |t|
    t.string   "session_id",        null: false
    t.datetime "created_at",        null: false
    t.datetime "updated_at",        null: false
    t.string   "file_file_name"
    t.string   "file_content_type"
    t.integer  "file_file_size"
    t.datetime "file_updated_at"
  end

  create_table "user_my_modules", force: :cascade do |t|
    t.integer  "user_id",        null: false
    t.integer  "my_module_id",   null: false
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
    t.integer  "assigned_by_id"
  end

  add_index "user_my_modules", ["assigned_by_id"], name: "index_user_my_modules_on_assigned_by_id", using: :btree
  add_index "user_my_modules", ["my_module_id"], name: "index_user_my_modules_on_my_module_id", using: :btree
  add_index "user_my_modules", ["user_id"], name: "index_user_my_modules_on_user_id", using: :btree

  create_table "user_organizations", force: :cascade do |t|
    t.integer  "role",            default: 1, null: false
    t.integer  "user_id",                     null: false
    t.integer  "organization_id",             null: false
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
    t.integer  "assigned_by_id"
  end

  add_index "user_organizations", ["assigned_by_id"], name: "index_user_organizations_on_assigned_by_id", using: :btree
  add_index "user_organizations", ["organization_id"], name: "index_user_organizations_on_organization_id", using: :btree
  add_index "user_organizations", ["user_id"], name: "index_user_organizations_on_user_id", using: :btree

  create_table "user_projects", force: :cascade do |t|
    t.integer  "role",           default: 0
    t.integer  "user_id",                    null: false
    t.integer  "project_id",                 null: false
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
    t.integer  "assigned_by_id"
  end

  add_index "user_projects", ["assigned_by_id"], name: "index_user_projects_on_assigned_by_id", using: :btree
  add_index "user_projects", ["project_id"], name: "index_user_projects_on_project_id", using: :btree
  add_index "user_projects", ["user_id"], name: "index_user_projects_on_user_id", using: :btree

  create_table "users", force: :cascade do |t|
    t.string   "full_name",                              null: false
    t.string   "initials",                               null: false
    t.string   "email",                  default: "",    null: false
    t.string   "encrypted_password",     default: "",    null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,     null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at",                             null: false
    t.datetime "updated_at",                             null: false
    t.string   "avatar_file_name"
    t.string   "avatar_content_type"
    t.integer  "avatar_file_size"
    t.datetime "avatar_updated_at"
    t.string   "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string   "unconfirmed_email"
    t.string   "time_zone",              default: "UTC"
    t.string   "invitation_token"
    t.datetime "invitation_created_at"
    t.datetime "invitation_sent_at"
    t.datetime "invitation_accepted_at"
    t.integer  "invitation_limit"
    t.integer  "invited_by_id"
    t.string   "invited_by_type"
    t.integer  "invitations_count",      default: 0
    t.integer  "tutorial_status",        default: 0,     null: false
    t.string   "wopi_token"
    t.integer  "wopi_token_ttl"
  end

  add_index "users", ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true, using: :btree
  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["invitation_token"], name: "index_users_on_invitation_token", unique: true, using: :btree
  add_index "users", ["invitations_count"], name: "index_users_on_invitations_count", using: :btree
  add_index "users", ["invited_by_id"], name: "index_users_on_invited_by_id", using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree

  create_table "wopi_actions", force: :cascade do |t|
    t.string  "action",      null: false
    t.string  "extension",   null: false
    t.string  "urlsrc",      null: false
    t.integer "wopi_app_id", null: false
  end

  add_index "wopi_actions", ["extension", "action"], name: "index_wopi_actions_on_extension_and_action", using: :btree

  create_table "wopi_apps", force: :cascade do |t|
    t.string  "name",              null: false
    t.string  "icon",              null: false
    t.integer "wopi_discovery_id", null: false
  end

  create_table "wopi_discoveries", force: :cascade do |t|
    t.integer "expires",           null: false
    t.string  "proof_key_mod",     null: false
    t.string  "proof_key_exp",     null: false
    t.string  "proof_key_old_mod", null: false
    t.string  "proof_key_old_exp", null: false
  end

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
  add_foreign_key "custom_fields", "organizations"
  add_foreign_key "custom_fields", "users"
  add_foreign_key "custom_fields", "users", column: "last_modified_by_id"
  add_foreign_key "experiments", "users", column: "archived_by_id"
  add_foreign_key "experiments", "users", column: "created_by_id"
  add_foreign_key "experiments", "users", column: "last_modified_by_id"
  add_foreign_key "experiments", "users", column: "restored_by_id"
  add_foreign_key "logs", "organizations"
  add_foreign_key "my_module_comments", "comments"
  add_foreign_key "my_module_comments", "my_modules"
  add_foreign_key "my_module_groups", "experiments"
  add_foreign_key "my_module_groups", "users", column: "created_by_id"
  add_foreign_key "my_module_tags", "users", column: "created_by_id"
  add_foreign_key "my_modules", "experiments"
  add_foreign_key "my_modules", "my_module_groups"
  add_foreign_key "my_modules", "users", column: "archived_by_id"
  add_foreign_key "my_modules", "users", column: "created_by_id"
  add_foreign_key "my_modules", "users", column: "last_modified_by_id"
  add_foreign_key "my_modules", "users", column: "restored_by_id"
  add_foreign_key "organizations", "users", column: "created_by_id"
  add_foreign_key "organizations", "users", column: "last_modified_by_id"
  add_foreign_key "project_comments", "comments"
  add_foreign_key "project_comments", "projects"
  add_foreign_key "projects", "organizations"
  add_foreign_key "projects", "users", column: "archived_by_id"
  add_foreign_key "projects", "users", column: "created_by_id"
  add_foreign_key "projects", "users", column: "last_modified_by_id"
  add_foreign_key "projects", "users", column: "restored_by_id"
  add_foreign_key "protocol_keywords", "organizations"
  add_foreign_key "protocol_protocol_keywords", "protocol_keywords"
  add_foreign_key "protocol_protocol_keywords", "protocols"
  add_foreign_key "protocols", "my_modules"
  add_foreign_key "protocols", "organizations"
  add_foreign_key "protocols", "protocols", column: "parent_id"
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
  add_foreign_key "result_assets", "assets"
  add_foreign_key "result_assets", "results"
  add_foreign_key "result_comments", "comments"
  add_foreign_key "result_comments", "results"
  add_foreign_key "result_tables", "results"
  add_foreign_key "result_tables", "tables"
  add_foreign_key "result_texts", "results"
  add_foreign_key "results", "my_modules"
  add_foreign_key "results", "users"
  add_foreign_key "results", "users", column: "archived_by_id"
  add_foreign_key "results", "users", column: "last_modified_by_id"
  add_foreign_key "results", "users", column: "restored_by_id"
  add_foreign_key "sample_comments", "comments"
  add_foreign_key "sample_comments", "samples"
  add_foreign_key "sample_custom_fields", "custom_fields"
  add_foreign_key "sample_custom_fields", "samples"
  add_foreign_key "sample_groups", "organizations"
  add_foreign_key "sample_groups", "users", column: "created_by_id"
  add_foreign_key "sample_groups", "users", column: "last_modified_by_id"
  add_foreign_key "sample_my_modules", "my_modules"
  add_foreign_key "sample_my_modules", "samples"
  add_foreign_key "sample_my_modules", "users", column: "assigned_by_id"
  add_foreign_key "sample_types", "organizations"
  add_foreign_key "sample_types", "users", column: "created_by_id"
  add_foreign_key "sample_types", "users", column: "last_modified_by_id"
  add_foreign_key "samples", "organizations"
  add_foreign_key "samples", "sample_groups"
  add_foreign_key "samples", "sample_types"
  add_foreign_key "samples", "users"
  add_foreign_key "samples", "users", column: "last_modified_by_id"
  add_foreign_key "step_assets", "assets"
  add_foreign_key "step_assets", "steps"
  add_foreign_key "step_comments", "comments"
  add_foreign_key "step_comments", "steps"
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
  add_foreign_key "user_my_modules", "my_modules"
  add_foreign_key "user_my_modules", "users"
  add_foreign_key "user_my_modules", "users", column: "assigned_by_id"
  add_foreign_key "user_organizations", "organizations"
  add_foreign_key "user_organizations", "users"
  add_foreign_key "user_organizations", "users", column: "assigned_by_id"
  add_foreign_key "user_projects", "projects"
  add_foreign_key "user_projects", "users"
  add_foreign_key "user_projects", "users", column: "assigned_by_id"
  add_foreign_key "wopi_actions", "wopi_apps"
  add_foreign_key "wopi_apps", "wopi_discoveries"
end
