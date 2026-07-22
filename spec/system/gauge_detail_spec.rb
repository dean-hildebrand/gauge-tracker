require "rails_helper"

RSpec.describe "Gauge detail grid", type: :system do
  let(:employee) { create(:user, :employee, email: "emma@example.com") }
  let(:manager)  { create(:user, :manager,  email: "mark@example.com") }

  def sign_in_as(user)
    visit new_user_session_path
    fill_in "Email", with: user.email
    fill_in "Password", with: "password"
    click_button "Sign in"
  end

  it "renders one row per period with smart labels and the three states" do
    gauge = create(:gauge, name: "2026 Electricity", created_by: employee,
                           starts_on: Date.new(2026, 1, 1), ends_on: Date.new(2026, 12, 31),
                           time_unit: :monthly)
    create(:reading, :approved, gauge: gauge, entered_by: employee,
                                approved_by: manager, period_start: Date.new(2026, 1, 1), value: 120)
    create(:reading, gauge: gauge, entered_by: employee,
                     period_start: Date.new(2026, 2, 1), value: 90)

    sign_in_as(employee)
    visit gauge_path(gauge)

    expect(page).to have_css(".period-row", count: 12)
    expect(page).to have_content("January 2026")
    expect(page).to have_content("December 2026")
    expect(page).to have_content("Approved")
    expect(page).to have_content("Pending")
    expect(page).to have_link("Add reading") # empty periods are actionable in Step 5
  end

  it "labels a truncated first period as a date range" do
    gauge = create(:gauge, created_by: employee,
                           starts_on: Date.new(2026, 3, 14), ends_on: Date.new(2026, 6, 30),
                           time_unit: :monthly)

    sign_in_as(employee)
    visit gauge_path(gauge)

    expect(page).to have_content("14–31 Mar 2026")
    expect(page).to have_content("April 2026")
  end
end
