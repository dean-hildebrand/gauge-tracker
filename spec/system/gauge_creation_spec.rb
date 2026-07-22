require "rails_helper"

RSpec.describe "Gauge creation", type: :system do
  let(:employee) { create(:user, :employee, email: "emma@example.com") }
  let(:manager)  { create(:user, :manager,  email: "mark@example.com") }

  def sign_in_as(user)
    visit new_user_session_path
    fill_in "Email", with: user.email
    fill_in "Password", with: "password"
    click_button "Sign in"
  end

  it "allows employees to create new gauges and lands on the detail page" do
    sign_in_as(employee)
    click_link "New gauge"

    fill_in "Name", with: "2026 Electricity"
    fill_in "Unit", with: "kWh"
    fill_in "Starts on", with: "2026-01-01"
    fill_in "Ends on", with: "2026-12-31"
    select "Monthly", from: "Time unit"

    click_button "Create gauge"

    gauge = Gauge.last
    expect(page).to have_current_path(gauge_path(gauge))
    expect(page).to have_content("Gauge created successfully.")
    expect(page).to have_content("2026 Electricity")
    expect(gauge.created_by).to eq(employee)
  end

  it "re-renders the form with errors when the submission is invalid" do
    sign_in_as(employee)
    click_link "New gauge"

    fill_in "Name", with: ""
    fill_in "Starts on", with: "2026-01-01"
    fill_in "Ends on", with: "2026-12-31"
    click_button "Create gauge"

    expect(page).to have_content("can't be blank")
    expect(page).to have_button("Create gauge")
    expect(Gauge.count).to eq(0)
  end

  it "refuses a manager the new-gauge form with a redirect and alert" do
    sign_in_as(manager)

    visit new_gauge_path

    expect(page).to have_current_path(root_path)
    expect(page).to have_content("Only employees can do that.")
  end
end
