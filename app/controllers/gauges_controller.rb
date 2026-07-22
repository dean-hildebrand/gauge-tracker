class GaugesController < ApplicationController
  def index
    @gauges = Gauge.order(created_at: :desc)
  end
end
