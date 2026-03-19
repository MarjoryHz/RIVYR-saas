class ClientPostCommentReactionsController < ApplicationController
  before_action :authenticate_user!

  def create
    @comment = ClientPostComment.find(params[:client_post_comment_id])
    emoji = params[:emoji].presence || "heart"

    existing = @comment.client_post_comment_reactions.find_by(user: current_user)
    if existing
      if existing.emoji == emoji
        existing.destroy
      else
        existing.update!(emoji: emoji)
      end
    else
      @comment.client_post_comment_reactions.create!(user: current_user, emoji: emoji)
    end

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "client_post_comment_#{@comment.id}",
          partial: "client_post_comments/comment",
          locals: { comment: @comment }
        )
      end
      format.html { redirect_back fallback_location: root_path }
    end
  end
end
