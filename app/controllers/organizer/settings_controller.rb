class Organizer::SettingsController < Organizer::BaseController
  def show
    @club = current_club
  end

  def update
    @club = current_club
    if @club.update(club_params)
      redirect_to organizer_settings_path, notice: "Settings saved."
    else
      render :show, status: :unprocessable_entity
    end
  end

  private

  def club_params
    params.require(:club).permit(
      :name, :contact_email, :primary_color, :font_choice,
      :legal_name, :ein, :ca_registry_number, :logo
    )
  end
end
