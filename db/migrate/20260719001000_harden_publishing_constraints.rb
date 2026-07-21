class HardenPublishingConstraints < ActiveRecord::Migration[8.1]
  def up
    require "bcrypt"
    now = connection.quote(Time.current)
    needs_legacy_identity = select_value("SELECT COUNT(*) FROM posts WHERE author_id IS NULL").to_i.positive? ||
      select_value("SELECT COUNT(*) FROM comments WHERE post_id IS NULL").to_i.positive?
    if needs_legacy_identity
      digest = connection.quote(BCrypt::Password.create(SecureRandom.hex(48)))
      unless select_value("SELECT id FROM users WHERE email = 'legacy-import@invalid.example'")
        execute <<~SQL.squish
          INSERT INTO users (email, password_digest, display_name, role, status, created_at, updated_at)
          VALUES ('legacy-import@invalid.example', #{digest}, 'Legacy import', 'author', 'suspended', #{now}, #{now})
        SQL
      end
      legacy_user_id = select_value("SELECT id FROM users WHERE email = 'legacy-import@invalid.example'")
      execute "UPDATE posts SET author_id = #{connection.quote(legacy_user_id)} WHERE author_id IS NULL"
      if select_value("SELECT COUNT(*) FROM comments WHERE post_id IS NULL").to_i.positive?
        unless select_value("SELECT id FROM posts WHERE slug = 'legacy-orphan-comments'")
          execute <<~SQL.squish
            INSERT INTO posts (title, body, author_id, slug, status, lock_version, created_at, updated_at)
            VALUES ('Legacy comments', 'Placeholder for migrated comments.', #{connection.quote(legacy_user_id)},
                    'legacy-orphan-comments', 'archived', 0, #{now}, #{now})
          SQL
        end
        legacy_post_id = select_value("SELECT id FROM posts WHERE slug = 'legacy-orphan-comments'")
        execute "UPDATE comments SET post_id = #{connection.quote(legacy_post_id)} WHERE post_id IS NULL"
      end
    end

    select_values("SELECT id FROM posts WHERE slug IS NULL OR slug = ''").each do |id|
      execute "UPDATE posts SET slug = 'legacy-article-#{id}' WHERE id = #{connection.quote(id)}"
    end
    execute "UPDATE posts SET title = 'Legacy article ' || id WHERE title IS NULL OR title = ''"
    execute "UPDATE posts SET body = 'Content unavailable.' WHERE body IS NULL OR body = ''"
    execute "UPDATE comments SET author = 'Anonymous' WHERE author IS NULL OR author = ''"
    execute "UPDATE comments SET body = 'Comment unavailable.' WHERE body IS NULL OR body = ''"
    execute "UPDATE comments SET ip_digest = 'legacy-' || id WHERE ip_digest IS NULL OR ip_digest = ''"

    change_column_null :posts, :author_id, false
    change_column_null :posts, :title, false
    change_column_null :posts, :body, false
    change_column_null :posts, :slug, false
    change_column_null :comments, :post_id, false
    change_column_null :comments, :author, false
    change_column_null :comments, :body, false
    change_column_null :comments, :ip_digest, false

    add_check_constraint :users, "role IN ('author','editor','moderator','admin')", name: "users_role_allowed"
    add_check_constraint :users, "status IN ('active','suspended')", name: "users_status_allowed"
    add_check_constraint :posts, "status IN ('draft','review','published','rejected','archived')", name: "posts_status_allowed"
    add_check_constraint :posts, "(status = 'published' AND published_at IS NOT NULL) OR (status <> 'published' AND published_at IS NULL)", name: "posts_publication_timestamp_consistent"
    add_check_constraint :comments, "status IN ('pending','approved','rejected','spam')", name: "comments_status_allowed"
    add_check_constraint :comments, "spam_score >= 0", name: "comments_spam_score_nonnegative"
  end

  def down
    remove_check_constraint :comments, name: "comments_spam_score_nonnegative"
    remove_check_constraint :comments, name: "comments_status_allowed"
    remove_check_constraint :posts, name: "posts_publication_timestamp_consistent"
    remove_check_constraint :posts, name: "posts_status_allowed"
    remove_check_constraint :users, name: "users_status_allowed"
    remove_check_constraint :users, name: "users_role_allowed"
    change_column_null :comments, :ip_digest, true
    change_column_null :comments, :body, true
    change_column_null :comments, :author, true
    change_column_null :comments, :post_id, true
    change_column_null :posts, :slug, true
    change_column_null :posts, :body, true
    change_column_null :posts, :title, true
    change_column_null :posts, :author_id, true
  end
end
