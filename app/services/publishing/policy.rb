module Publishing
  class Policy
    def initialize(user, post = nil)
      @user = user
      @post = post
    end

    def create?
      active? && %w[author editor admin].include?(@user.role)
    end

    def edit?
      return false unless active?
      return true if @user.editor?
      @post&.author_id == @user.id && %w[draft rejected].include?(@post.status)
    end

    def destroy?
      active? && @user.admin? && @post&.status != "published" && @post.revisions.none? && @post.publication_events.none?
    end

    private

    def active?
      @user&.active?
    end
  end
end
