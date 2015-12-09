class LinksController < ApplicationController
  before_action :authenticate_user!, except: [:profile]
  before_action :correct_link, only: [:edit, :update, :destroy, :move_up, :move_down, :enable, :disable]
  # before_filter :track_ahoy_visit, only: [:profile]

  def index
    @links = current_user.links.order(:row_order)
  end

  def profile
    @user = User.friendly.find(params[:id])
    @links = @user.links.order(:row_order)
    if user_signed_in?
      ahoy.track("Profile visit", visited_user: @user.id) unless @user == current_user
    else
      ahoy.track("Profile visit", visited_user: @user.id)
    end
  end

  def new
    if current_user.subscriptions.blank? || current_user.subscriptions.take.canceled_now?
      authorize! :new, Link, :message => "Singlelink.me Free has a limit of 5 links. You can upgrade your subscription to Pro for more links."
    else
      authorize! :new, Link, :message => "Singlelink.me Pro has a limit of 25 links. To add a new link, you can edit or delete a link."
    end
    @link = Link.new
  end

  def create
    authorize! :create, Link
    @link = current_user.links.build(link_params)

    if @link.save
      redirect_to links_url, notice: 'Link was successfully created.'
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @link.update(link_params)
      redirect_to links_url, notice: 'Link was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    @link.destroy
    redirect_to links_url, notice: 'Link was successfully destroyed.'
  end

  def move_up
    @link.update_attribute :row_order_position, :up
    redirect_to links_url
  end

  def move_down
    @link.update_attribute :row_order_position, :down
    redirect_to links_url
  end

  def enable
    authorize! :enable, Link, :message => "Singlelink.me Free has a limit of 5 links. You can upgrade your subscription to Pro for more links."
    @link.disable = false
    @link.save
    redirect_to links_url
  end

  def disable
    @link.disable = true
    @link.save
    redirect_to links_url
  end

  private
    def correct_link
      @link = Link.find(params[:id])
      redirect_to links_url, alert: 'Unauthorized access' unless @link.user == current_user
    end

    def link_params
      params.require(:link).permit(:url)
    end

    # def track_visit
    #   ahoy.track_visit
    # end
end
