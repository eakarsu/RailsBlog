class RevisionsController < ApplicationController
  before_action :authenticate!
  before_action :set_post
  before_action :authorize_view!
  before_action :set_revision, only: %i[show restore]

  def index
    @revisions = @post.revisions.includes(:editor).order(number: :desc)
  end

  def show; end

  def restore
    if params[:reason].to_s.strip.blank?
      redirect_to post_revision_path(@post, @revision), alert: "A restore reason is required."
      return
    end
    Publishing::PostEditor.call(post: @post, actor: current_user,
                                attributes: { title: @revision.title, body: @revision.body },
                                reason: "Restored revision #{@revision.number}: #{params[:reason]}")
    redirect_to @post, notice: "Revision #{@revision.number} restored for review."
  end

  private

  def set_post
    @post = Post.find_by!(slug: params[:post_slug])
  end

  def set_revision
    @revision = @post.revisions.find(params[:id])
  end

  def authorize_view!
    forbidden unless current_user.editor? || @post.author_id == current_user.id
  end
end
