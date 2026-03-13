class TodoCategoriesController < ApplicationController
  def create
    @todo_category = current_user.todo_categories.new(todo_category_params.merge(system: false))
    authorize @todo_category

    if @todo_category.save
      redirect_to todo_list_path, notice: "Categorie ajoutee."
    else
      redirect_to todo_list_path, alert: @todo_category.errors.full_messages.to_sentence
    end
  end

  def update
    @todo_category = current_user.todo_categories.find(params[:id])
    authorize @todo_category

    if @todo_category.update(todo_category_params)
      redirect_to todo_list_path, notice: "Categorie mise a jour."
    else
      redirect_to todo_list_path, alert: @todo_category.errors.full_messages.to_sentence
    end
  end

  def destroy
    @todo_category = current_user.todo_categories.find(params[:id])
    authorize @todo_category

    if @todo_category.destroy
      redirect_to todo_list_path, notice: "Categorie supprimee."
    else
      redirect_to todo_list_path, alert: @todo_category.errors.full_messages.to_sentence
    end
  end

  private

  def todo_category_params
    params.require(:todo_category).permit(:name)
  end
end
