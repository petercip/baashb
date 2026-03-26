class Organizer::MembersController < Organizer::BaseController
  before_action :set_member, only: %i[show edit update destroy]

  def index
    @members = current_club.members.order(:name)
  end

  def show
  end

  def new
    @member = current_club.members.new
  end

  def create
    @member = current_club.members.new(member_params)
    if @member.save
      # TODO: send organizer invite magic link
      redirect_to organizer_members_path, notice: "#{@member.name} added."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @member.update(member_params)
      redirect_to organizer_member_path(@member), notice: "Member updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @member.update!(status: :removed)
    redirect_to organizer_members_path, notice: "#{@member.name} removed."
  end

  private

  def set_member
    @member = current_club.members.friendly.find(params[:slug])
  end

  def member_params
    params.require(:member).permit(:name, :email, :role, :bio)
  end
end
