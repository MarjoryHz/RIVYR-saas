class ClientPostCommentsController < ApplicationController
  before_action :authenticate_user!

  def create
    @client_post = ClientPost.find(params[:client_post_id])
    @comment = @client_post.client_post_comments.build(body: params[:client_post_comment][:body], user: current_user)

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
end
