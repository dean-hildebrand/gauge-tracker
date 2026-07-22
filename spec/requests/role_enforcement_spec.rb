require "rails_helper"

RSpec.describe "Role and ownership enforcement", type: :request do
  let(:employee) { create(:user, :employee) }
  let(:other)    { create(:user, :employee) }
  let(:manager)  { create(:user, :manager) }
  let(:gauge)    { create(:gauge, created_by: employee) }

  describe "a manager acting as an employee" do
    before { sign_in manager }

    it "cannot create a gauge" do
      post gauges_path, params: { gauge: { name: "X", starts_on: "2026-01-01", ends_on: "2026-12-31", unit: "kWh", time_unit: "monthly" } }

      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to eq("Only employees can do that.")
      expect(Gauge.where(name: "X")).to be_empty
    end

    it "cannot create a reading" do
      post gauge_readings_path(gauge), params: { reading: { period_start: "2026-01-01", value: 10 } }

      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to eq("Only employees can do that.")
      expect(gauge.readings).to be_empty
    end

    it "cannot update a reading" do
      reading = create(:reading, gauge: gauge, entered_by: employee, value: 10)

      patch reading_path(reading), params: { reading: { value: 99 } }

      expect(response).to redirect_to(root_path)
      expect(reading.reload.value).to eq(10)
    end
  end

  describe "an employee acting on a gauge they did not create" do
    before { sign_in other }

    it "cannot create a reading" do
      post gauge_readings_path(gauge), params: { reading: { period_start: "2026-01-01", value: 10 } }

      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to eq("You can only manage readings on gauges you created.")
      expect(gauge.readings).to be_empty
    end

    it "cannot update a reading" do
      reading = create(:reading, gauge: gauge, entered_by: employee, value: 10)

      patch reading_path(reading), params: { reading: { value: 99 } }

      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to eq("You can only manage readings on gauges you created.")
      expect(reading.reload.value).to eq(10)
    end
  end
end
