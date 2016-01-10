class CommentsController < ApplicationController
  def create
    @post = Post.find(params[:id])
    if @post.comments.create(comment_params)
        redirect_to @post,
                    notice: 'Comment was successfully created'
    else
          redirect_to @post,
                  notice: 'Error creating comment'
    end
  end

  private
    def comment_params
      params.require(:comment).permit(:author, :body)
    end
end
