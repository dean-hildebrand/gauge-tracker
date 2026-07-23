class ReadingsController < ApplicationController
  before_action :require_employee!, except: [ :approve ]
  before_action :require_manager!,  only:   [ :approve ]
  before_action :set_gauge,   only: [ :new, :create ]
  before_action :set_reading, only: [ :edit, :update, :approve ]
  before_action :require_gauge_owner!, except: [ :approve ]

  def new
    @reading = @gauge.readings.new(period_start: params[:period_start])
  end

  def create
    @reading = @gauge.readings.new(reading_params.merge(entered_by: current_user))

    if @reading.save
      render_row
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @reading.update(reading_params)
      render_row
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def approve
    @reading.approve!(current_user)

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to @gauge, notice: "Reading approved." }
    end
  rescue Reading::ImmutableError
    redirect_to @gauge, alert: "That reading was already approved."
  end

  private

  def set_gauge
    @gauge = Gauge.find(params[:gauge_id])
  end

  def set_reading
    @reading = Reading.find_by(id: params[:id])
    @gauge = @reading&.gauge
  end

  # Only the employee who created the gauge may add or edit its readings.
  def require_gauge_owner!
    return if @gauge && @gauge.created_by_id == current_user.id

    redirect_to root_path, alert: "You can only manage readings on gauges you created."
  end

  def render_row
    render partial: "readings/row",
           locals: { gauge: @gauge, period_start: @reading.period_start, reading: @reading }
  end

  def reading_params
    # period_start is the reading's key, only set on create, not on update.
    permitted = action_name == "create" ? [ :value, :period_start ] : [ :value ]
    params.require(:reading).permit(*permitted)
  end
end
