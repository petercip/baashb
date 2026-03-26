class Organizer::EventsController < Organizer::BaseController
  before_action :set_event, only: %i[show edit update destroy attendees cancel duplicate]

  def index
    @events = current_club.events.order(starts_at: :desc)
  end

  def show
  end

  def new
    @event = current_club.events.new
  end

  def create
    @event = current_club.events.new(event_params)
    if @event.save
      redirect_to organizer_event_path(@event), notice: "Event created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @event.update(event_params)
      redirect_to organizer_event_path(@event), notice: "Event updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @event.destroy
    redirect_to organizer_events_path, notice: "Event deleted."
  end

  def attendees
    @rsvps = @event.rsvps.confirmed.includes(:member)
  end

  def cancel
    @event.update!(status: :cancelled, cancelled_at: Time.current)
    redirect_to organizer_event_path(@event), notice: "Event cancelled."
  end

  def duplicate
    new_event = @event.dup
    new_event.name       = "#{@event.name} (copy)"
    new_event.slug       = nil
    new_event.status     = :draft
    new_event.starts_at  = nil
    new_event.ends_at    = nil
    new_event.save!
    redirect_to edit_organizer_event_path(new_event), notice: "Event duplicated. Update the date and publish when ready."
  end

  private

  def set_event
    @event = current_club.events.friendly.find(params[:slug])
  end

  def event_params
    params.require(:event).permit(
      :name, :description, :starts_at, :ends_at,
      :venue, :capacity, :price_cents, :refund_cutoff_at, :status
    )
  end
end
