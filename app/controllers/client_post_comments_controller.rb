class ClientPostCommentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_comment, only: [:update, :destroy]
  before_action :authorize_comment_owner!, only: [:update, :destroy]

  def create
    @client_post = ClientPost.find(params[:client_post_id])
    @comment = @client_post.client_post_comments.build(comment_params.merge(user: current_user))

    if @comment.save
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_back fallback_location: root_path }
      end
    else
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace("comment_form_#{@client_post.id}", partial: "client_post_comments/form", locals: { client_post: @client_post, comment: @comment }) }
        format.html { redirect_back fallback_location: root_path }
      end
    end
  end

  def update
    if @comment.update(comment_params)
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
    else
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "client_post_comment_#{@comment.id}",
            partial: "client_post_comments/comment",
            locals: { comment: @comment, editing: true }
          )
        end
        format.html { redirect_back fallback_location: root_path }
      end
    end
  end

  def destroy
    @client_post = @comment.client_post
    @comment.destroy

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_back fallback_location: root_path }
    end
  end

  private

  def set_comment
    @comment = ClientPostComment.find(params[:id])
  end

  def authorize_comment_owner!
    redirect_back fallback_location: root_path, alert: "Vous n'êtes pas autorisé à modifier ce commentaire." unless @comment.user == current_user
  end

  def comment_params
    params.fetch(:client_post_comment, {}).permit(:body)
  end
end
