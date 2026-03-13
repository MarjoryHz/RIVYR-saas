class TodoTasksController < ApplicationController
  def create
    @todo_task = current_user.todo_tasks.new(todo_task_params)
    authorize @todo_task

    if @todo_task.save
      redirect_to todo_list_path, notice: "Tache ajoutee."
    else
      redirect_to todo_list_path, alert: @todo_task.errors.full_messages.to_sentence
    end
  end

  def update
    @todo_task = current_user.todo_tasks.find(params[:id])
    authorize @todo_task

    if @todo_task.update(todo_task_params)
      redirect_to todo_list_path, notice: "Tache mise a jour."
    else
      redirect_to todo_list_path, alert: @todo_task.errors.full_messages.to_sentence
    end
  end

  def destroy
    @todo_task = current_user.todo_tasks.find(params[:id])
    authorize @todo_task

    @todo_task.destroy
    redirect_to todo_list_path, notice: "Tache supprimee."
  end

  private

  def todo_task_params
    params.require(:todo_task).permit(:todo_category_id, :title, :description, :status, :priority, :due_on)
  end
end
