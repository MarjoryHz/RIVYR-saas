class ApplicationController < ActionController::Base
  before_action :authenticate_user!

  private

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
