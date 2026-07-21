class FeedsController < ApplicationController
  def show
    @posts = Post.published.recent_first.limit(25)
    fresh_when etag: @posts, last_modified: @posts.maximum(:updated_at), public: true
  end
end
