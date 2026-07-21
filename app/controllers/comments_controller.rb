class CommentsController < ApplicationController
  before_action :authenticate!, only: %i[index moderate]

  def index
    require_moderator!
    @comments = Comment.where(status: %w[pending spam]).includes(post: :author).order(created_at: :asc).limit(100)
  end

  def create
    post = Post.published.find_by!(slug: params[:post_slug])
    if params.dig(:comment, :website).present?
      head :accepted
      return
    end
    ip_digest = OpenSSL::HMAC.hexdigest("SHA256", Rails.application.secret_key_base, request.remote_ip.to_s)
    comment = post.comments.new(comment_params.merge(ip_digest: ip_digest))
    if comment.save
      redirect_to post, notice: "Comment received for moderation."
    else
      redirect_to post, alert: comment.errors.full_messages.to_sentence
    end
  end

  def moderate
    require_moderator!
    comment = Comment.find(params[:id])
    Publishing::CommentModerator.call(comment: comment, moderator: current_user,
                                      decision: params[:decision], reason: params[:reason])
    redirect_to comment.post, notice: "Comment moderation recorded."
  rescue Publishing::CommentModerator::InvalidDecision => error
    render json: { error: error.message }, status: :unprocessable_entity
  end

  private

  def comment_params
    params.require(:comment).permit(:author, :email, :body)
  end
end
