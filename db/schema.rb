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

ActiveRecord::Schema[8.1].define(version: 2026_07_19_001000) do
  create_table "active_storage_attachments", force: :cascade do |t|
    t.integer "blob_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.string "name", null: false
    t.integer "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", precision: nil, null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.integer "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "categories", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_categories_on_slug", unique: true
  end

  create_table "comments", force: :cascade do |t|
    t.string "author", null: false
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.string "email"
    t.string "ip_digest", null: false
    t.datetime "moderated_at", precision: nil
    t.integer "moderated_by_id"
    t.text "moderation_reason"
    t.integer "post_id", null: false
    t.integer "spam_score", default: 0, null: false
    t.string "status", default: "pending", null: false
    t.datetime "updated_at", null: false
    t.index ["moderated_by_id"], name: "index_comments_on_moderated_by_id"
    t.index ["post_id", "status"], name: "index_comments_on_post_id_and_status"
    t.index ["post_id"], name: "index_comments_on_post_id"
    t.check_constraint "spam_score >= 0", name: "comments_spam_score_nonnegative"
    t.check_constraint "status IN ('pending','approved','rejected','spam')", name: "comments_status_allowed"
  end

  create_table "import_runs", force: :cascade do |t|
    t.integer "actor_id", null: false
    t.datetime "created_at", null: false
    t.boolean "dry_run", default: true, null: false
    t.text "errors_json", default: "[]", null: false
    t.string "payload_sha256", null: false
    t.integer "record_count", default: 0, null: false
    t.string "status", null: false
    t.datetime "updated_at", null: false
    t.index ["actor_id"], name: "index_import_runs_on_actor_id"
  end

  create_table "moderation_events", force: :cascade do |t|
    t.integer "comment_id", null: false
    t.datetime "created_at", null: false
    t.string "from_status", null: false
    t.integer "moderator_id", null: false
    t.text "reason", null: false
    t.string "to_status", null: false
    t.datetime "updated_at", null: false
    t.index ["comment_id"], name: "index_moderation_events_on_comment_id"
    t.index ["moderator_id"], name: "index_moderation_events_on_moderator_id"
  end

  create_table "post_categories", force: :cascade do |t|
    t.integer "category_id", null: false
    t.integer "post_id", null: false
    t.index ["category_id"], name: "index_post_categories_on_category_id"
    t.index ["post_id", "category_id"], name: "index_post_categories_on_post_id_and_category_id", unique: true
    t.index ["post_id"], name: "index_post_categories_on_post_id"
  end

  create_table "post_tags", force: :cascade do |t|
    t.integer "post_id", null: false
    t.integer "tag_id", null: false
    t.index ["post_id", "tag_id"], name: "index_post_tags_on_post_id_and_tag_id", unique: true
    t.index ["post_id"], name: "index_post_tags_on_post_id"
    t.index ["tag_id"], name: "index_post_tags_on_tag_id"
  end

  create_table "posts", force: :cascade do |t|
    t.string "author"
    t.integer "author_id", null: false
    t.text "body", null: false
    t.string "canonical_url"
    t.datetime "created_at", null: false
    t.datetime "discarded_at", precision: nil
    t.text "excerpt"
    t.integer "lock_version", default: 0, null: false
    t.datetime "published_at", precision: nil
    t.string "seo_description"
    t.string "seo_title"
    t.string "slug", null: false
    t.string "status", default: "draft", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["author_id"], name: "index_posts_on_author_id"
    t.index ["slug"], name: "index_posts_on_slug", unique: true
    t.index ["status", "published_at"], name: "index_posts_on_status_and_published_at"
    t.check_constraint "(status = 'published' AND published_at IS NOT NULL) OR (status <> 'published' AND published_at IS NULL)", name: "posts_publication_timestamp_consistent"
    t.check_constraint "status IN ('draft','review','published','rejected','archived')", name: "posts_status_allowed"
  end

  create_table "publication_events", force: :cascade do |t|
    t.integer "actor_id", null: false
    t.datetime "created_at", null: false
    t.string "from_status", null: false
    t.integer "post_id", null: false
    t.text "reason"
    t.string "to_status", null: false
    t.datetime "updated_at", null: false
    t.index ["actor_id"], name: "index_publication_events_on_actor_id"
    t.index ["post_id"], name: "index_publication_events_on_post_id"
  end

  create_table "revisions", force: :cascade do |t|
    t.text "body", null: false
    t.string "content_sha256", null: false
    t.datetime "created_at", null: false
    t.integer "editor_id", null: false
    t.integer "number", null: false
    t.integer "post_id", null: false
    t.text "reason"
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["editor_id"], name: "index_revisions_on_editor_id"
    t.index ["post_id", "number"], name: "index_revisions_on_post_id_and_number", unique: true
    t.index ["post_id"], name: "index_revisions_on_post_id"
  end

  create_table "tags", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_tags_on_slug", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "display_name", null: false
    t.string "email", null: false
    t.datetime "last_login_at", precision: nil
    t.string "password_digest", null: false
    t.string "role", default: "author", null: false
    t.string "status", default: "active", null: false
    t.datetime "updated_at", null: false
    t.index "lower(email)", name: "index_users_on_lower_email", unique: true
    t.check_constraint "role IN ('author','editor','moderator','admin')", name: "users_role_allowed"
    t.check_constraint "status IN ('active','suspended')", name: "users_status_allowed"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "comments", "posts"
  add_foreign_key "comments", "users", column: "moderated_by_id"
  add_foreign_key "import_runs", "users", column: "actor_id"
  add_foreign_key "moderation_events", "comments"
  add_foreign_key "moderation_events", "users", column: "moderator_id"
  add_foreign_key "post_categories", "categories"
  add_foreign_key "post_categories", "posts"
  add_foreign_key "post_tags", "posts"
  add_foreign_key "post_tags", "tags"
  add_foreign_key "posts", "users", column: "author_id"
  add_foreign_key "publication_events", "posts"
  add_foreign_key "publication_events", "users", column: "actor_id"
  add_foreign_key "revisions", "posts"
  add_foreign_key "revisions", "users", column: "editor_id"
end
