class CompletePublishingPlatform < ActiveRecord::Migration[6.1]
  def change
    create_table :users do |t|
      t.string :email, null: false
      t.string :password_digest, null: false
      t.string :display_name, null: false
      t.string :role, null: false, default: "author"
      t.string :status, null: false, default: "active"
      t.datetime :last_login_at
      t.timestamps
    end
    add_index :users, "lower(email)", unique: true, name: "index_users_on_lower_email"

    change_table :posts do |t|
      t.references :author, foreign_key: { to_table: :users }
      t.string :slug
      t.string :status, null: false, default: "draft"
      t.text :excerpt
      t.string :seo_title
      t.string :seo_description
      t.string :canonical_url
      t.datetime :published_at
      t.integer :lock_version, null: false, default: 0
      t.datetime :discarded_at
    end
    add_index :posts, :slug, unique: true
    add_index :posts, %i[status published_at]

    create_table :revisions do |t|
      t.references :post, null: false, foreign_key: true
      t.references :editor, null: false, foreign_key: { to_table: :users }
      t.integer :number, null: false
      t.string :title, null: false
      t.text :body, null: false
      t.text :reason
      t.string :content_sha256, null: false
      t.timestamps
    end
    add_index :revisions, %i[post_id number], unique: true

    create_table :categories do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.timestamps
    end
    add_index :categories, :slug, unique: true

    create_table :tags do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.timestamps
    end
    add_index :tags, :slug, unique: true

    create_table :post_categories do |t|
      t.references :post, null: false, foreign_key: true
      t.references :category, null: false, foreign_key: true
    end
    add_index :post_categories, %i[post_id category_id], unique: true

    create_table :post_tags do |t|
      t.references :post, null: false, foreign_key: true
      t.references :tag, null: false, foreign_key: true
    end
    add_index :post_tags, %i[post_id tag_id], unique: true

    change_table :comments do |t|
      t.string :email
      t.string :status, null: false, default: "pending"
      t.string :ip_digest
      t.integer :spam_score, null: false, default: 0
      t.references :moderated_by, foreign_key: { to_table: :users }
      t.text :moderation_reason
      t.datetime :moderated_at
    end
    add_index :comments, %i[post_id status]

    create_table :moderation_events do |t|
      t.references :comment, null: false, foreign_key: true
      t.references :moderator, null: false, foreign_key: { to_table: :users }
      t.string :from_status, null: false
      t.string :to_status, null: false
      t.text :reason, null: false
      t.timestamps
    end

    create_table :publication_events do |t|
      t.references :post, null: false, foreign_key: true
      t.references :actor, null: false, foreign_key: { to_table: :users }
      t.string :from_status, null: false
      t.string :to_status, null: false
      t.text :reason
      t.timestamps
    end

    create_table :import_runs do |t|
      t.references :actor, null: false, foreign_key: { to_table: :users }
      t.string :status, null: false
      t.boolean :dry_run, null: false, default: true
      t.integer :record_count, null: false, default: 0
      t.string :payload_sha256, null: false
      t.text :errors_json, null: false, default: "[]"
      t.timestamps
    end

    create_table :active_storage_blobs do |t|
      t.string :key, null: false
      t.string :filename, null: false
      t.string :content_type
      t.text :metadata
      t.string :service_name, null: false
      t.bigint :byte_size, null: false
      t.string :checksum
      t.datetime :created_at, null: false
      t.index :key, unique: true
    end

    create_table :active_storage_attachments do |t|
      t.string :name, null: false
      t.references :record, null: false, polymorphic: true, index: false
      t.references :blob, null: false, foreign_key: { to_table: :active_storage_blobs }
      t.datetime :created_at, null: false
      t.index %i[record_type record_id name blob_id], unique: true, name: "index_active_storage_attachments_uniqueness"
    end

    create_table :active_storage_variant_records do |t|
      t.belongs_to :blob, null: false, index: false, foreign_key: { to_table: :active_storage_blobs }
      t.string :variation_digest, null: false
      t.index %i[blob_id variation_digest], unique: true, name: "index_active_storage_variant_records_uniqueness"
    end
  end
end
