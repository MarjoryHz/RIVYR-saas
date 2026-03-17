class CandidateNotesController < ApplicationController
  before_action :set_candidate
  before_action :set_note, only: [ :update, :destroy ]

  def create
    @note = @candidate.candidate_notes.build(note_params)
    @note.user = current_user

    if @note.save
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to dashboard_candidate_path(@candidate) }
      end
    else
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "notes-form",
            partial: "candidate_notes/form",
            locals: { candidate: @candidate, note: @note }
          )
        end
        format.html { redirect_to dashboard_candidate_path(@candidate) }
      end
    end
  end

  def update
    return unless @note.user == current_user

    if @note.update(note_params)
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to dashboard_candidate_path(@candidate) }
      end
    else
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "candidate-note-#{@note.id}",
            partial: "candidate_notes/candidate_note",
            locals: { note: @note }
          )
        end
        format.html { redirect_to dashboard_candidate_path(@candidate) }
      end
    end
  end

  def destroy
    @note.destroy if @note.user == current_user

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to dashboard_candidate_path(@candidate) }
    end
  end

  private

  def set_candidate
    @candidate = Candidate.find(params[:candidate_id])
  end

  def set_note
    @note = @candidate.candidate_notes.find(params[:id])
  end

  def note_params
    params.require(:candidate_note).permit(:body)
  end
end
