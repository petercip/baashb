class Organizer::AnnouncementsController < Organizer::BaseController
  before_action :set_announcement, only: %i[show edit update destroy]

  def index
    @drafts = current_club.announcements.drafts.order(created_at: :desc)
    @sent   = current_club.announcements.sent
  end

  def show
  end

  def new
    @announcement = current_club.announcements.new(
      author:           current_member,
      recipient_scope:  "all_members"
    )
  end

  def create
    @announcement = current_club.announcements.new(
      announcement_params.merge(author: current_member)
    )
    @announcement.sent_at = Time.current if params[:send_now].present?

    if @announcement.save
      msg = @announcement.sent? ? "Announcement sent." : "Announcement saved as draft."
      redirect_to organizer_announcement_path(@announcement), notice: msg
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    # Mark sent_at if organizer clicks "Send now" and it hasn't been sent yet.
    @announcement.sent_at = Time.current if params[:send_now].present? && !@announcement.sent?

    # announcement params may be absent when posting from "Send now" button on show page
    attrs = params[:announcement].present? ? announcement_params : {}

    if @announcement.update(attrs)
      msg = @announcement.sent? ? "Announcement sent." : "Announcement updated."
      redirect_to organizer_announcement_path(@announcement), notice: msg
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @announcement.destroy
    redirect_to organizer_announcements_path, notice: "Announcement deleted."
  end

  private

  def set_announcement
    @announcement = current_club.announcements.friendly.find(params[:slug])
  end

  def announcement_params
    params.require(:announcement).permit(:subject, :body, :recipient_scope, :target_event_id)
  end
end
