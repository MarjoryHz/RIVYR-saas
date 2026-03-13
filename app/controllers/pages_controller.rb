class PagesController < ApplicationController
  skip_before_action :authenticate_user!, only: [ :home, :contact, :create_contact ]

  def home
    redirect_to missions_path if user_signed_in?
  end

  def contact
    @contact_form = ContactForm.new
  end

  def create_contact
    @contact_form = ContactForm.new(contact_params)

    if @contact_form.submit
      redirect_to contact_path, notice: "Merci, votre demande a bien ete recue. Nous reviendrons vers vous rapidement."
    else
      render :contact, status: :unprocessable_entity
    end
  end

  private

  def contact_params
    params.require(:contact_form).permit(:full_name, :email, :company, :subject, :message)
  end
end
