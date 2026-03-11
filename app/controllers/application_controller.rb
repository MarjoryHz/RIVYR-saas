class ApplicationController < ActionController::Base
  include Pundit::Authorization

  before_action :authenticate_user!
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  private

  def user_not_authorized
    redirect_back_or_to(root_path, alert: "Vous n'etes pas autorise a effectuer cette action.")
  end

  def paginate(scope, per_page: 20)
    total_count = scope.count
    total_pages = (total_count / per_page.to_f).ceil
    total_pages = 1 if total_pages.zero?

    page = params[:page].to_i
    page = 1 if page < 1
    page = total_pages if page > total_pages

    @page = page
    @per_page = per_page
    @total_pages = total_pages
    @total_count = total_count

    scope.offset((page - 1) * per_page).limit(per_page)
  end
end
