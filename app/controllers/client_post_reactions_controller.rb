class ClientPostReactionsController < ApplicationController
  before_action :authenticate_user!

  def create
    @client_post = ClientPost.find(params[:client_post_id])
    emoji = params[:emoji]

    existing = @client_post.client_post_reactions.find_by(user: current_user)
    if existing
      if existing.emoji == emoji
        existing.destroy
      else
        existing.update!(emoji: emoji)
      end
    else
      @client_post.client_post_reactions.create!(user: current_user, emoji: emoji)
    end

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.replace(
            "reactions_#{@client_post.id}",
            partial: "client_post_reactions/reactions",
            locals: { post: @client_post, current_user: current_user }
          ),
          turbo_stream.replace(
            "company_contribution_engagement_#{@client_post.id}",
            partial: "pages/company_contribution_engagement",
            locals: {
              post: @client_post,
              current_user: current_user,
              showcase_url: "#{request.base_url}#{Rails.application.routes.url_helpers.company_showcase_path(client_id: @client_post.client_id)}",
              dom_prefix: "company_contribution",
              modal_target: "comments_modal_#{@client_post.id}"
            }
          ),
          turbo_stream.replace(
            "company_contribution_modal_engagement_#{@client_post.id}",
            partial: "pages/company_contribution_engagement",
            locals: {
              post: @client_post,
              current_user: current_user,
              showcase_url: "#{request.base_url}#{Rails.application.routes.url_helpers.company_showcase_path(client_id: @client_post.client_id)}",
              dom_prefix: "company_contribution_modal",
              modal_target: "comments_modal_#{@client_post.id}",
              light_mode: true,
              comment_click: "document.getElementById('comments_#{@client_post.id}')?.scrollIntoView({ behavior: 'smooth', block: 'start' })"
            }
          )
        ]
      end
      format.html { redirect_back fallback_location: root_path }
    end
  end
end
