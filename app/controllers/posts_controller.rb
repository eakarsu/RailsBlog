class PostsController < ApplicationController
  before_action :authenticate!, except: %i[index show]
  before_action :set_post, only: %i[show edit update destroy submit publish reject archive]

  def index
    @posts = Post.published.includes(:author, :categories, :tags).recent_first.limit(50)
    if params[:mine] == "1" && signed_in?
      @posts = Post.where(author: current_user).includes(:author, :categories, :tags).order(updated_at: :desc).limit(50)
    end
  end

  def editorial
    require_editor!
    @posts = Post.where(status: %w[review rejected]).includes(:author).order(updated_at: :asc).limit(100)
  end

  def show
    not_found and return unless visible?(@post)
    @comments = @post.comments.visible.order(created_at: :asc)
    @comment = Comment.new
  end

  def new
    forbidden and return unless Publishing::Policy.new(current_user).create?
    @post = current_user.posts.new
  end

  def edit
    forbidden unless Publishing::Policy.new(current_user, @post).edit?
  end

  def create
    forbidden and return unless Publishing::Policy.new(current_user).create?
    @post = current_user.posts.new(post_params)
    if @post.save
      redirect_to @post, notice: "Draft created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    Publishing::PostEditor.call(post: @post, actor: current_user, attributes: post_params.to_h, reason: params[:revision_reason])
    redirect_to @post, notice: "Article updated; published changes require review."
  rescue ActiveRecord::RecordInvalid
    render :edit, status: :unprocessable_entity
  end

  def destroy
    forbidden and return unless Publishing::Policy.new(current_user, @post).destroy?
    @post.destroy!
    redirect_to posts_url, notice: "Article deleted."
  end

  %w[submit publish reject archive].each do |event|
    define_method(event) do
      Publishing::PostWorkflow.call(post: @post, actor: current_user, action: event, reason: params[:reason])
      redirect_to @post, notice: "Article moved to #{@post.status}."
    rescue Publishing::PostWorkflow::InvalidTransition => error
      redirect_to @post, alert: error.message
    end
  end

  private

  def set_post
    @post = Post.find_by!(slug: params[:slug])
  end

  def visible?(post)
    post.status == "published" || (signed_in? && (current_user.editor? || post.author_id == current_user.id))
  end

  def post_params
    params.require(:post).permit(:title, :body, :excerpt, :seo_title, :seo_description, :canonical_url,
                                 :hero_image, :lock_version, category_ids: [], tag_ids: [])
  end
end
