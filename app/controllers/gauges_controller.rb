class GaugesController < ApplicationController
  before_action :require_employee!, only: [ :new, :create, :edit, :update ]
  before_action :set_owned_gauge, only: [ :edit, :update ]
  include Pagy::Method
  def index
    @gauges = Gauge.order(created_at: :desc)
    @pagy, @gauges = pagy(:countish, @gauges, limit: 10, page: params[:page])
  end

  def show
  @gauge = Gauge.find(params[:id])
  @pagy, @periods = pagy(:offset, @gauge.periods, limit: 10, page: params[:page])

  @readings_by_period = @gauge.readings
                              .where(period_start: @periods.map(&:first))
                              .index_by(&:period_start)
end

  def new
    @gauge = Gauge.new(unit: "kWh", time_unit: :monthly)
  end

  def create
    @gauge = Gauge.new(gauge_params.merge(created_by: current_user))

    if @gauge.save
      redirect_to @gauge, notice: "Gauge created successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @gauge.update(gauge_params)
      redirect_to @gauge, notice: "Gauge updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private
  # Employees can only edit gauges they created.
  def set_owned_gauge
    @gauge = current_user.gauges.find_by(id: params[:id])
    return if @gauge

    redirect_to root_path, alert: "You can only edit gauges you created."
  end

  def gauge_params
    params.require(:gauge).permit(:name, :unit, :starts_on, :ends_on, :time_unit)
  end
end
