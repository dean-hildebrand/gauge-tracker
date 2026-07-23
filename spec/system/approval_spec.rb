require "rails_helper"

RSpec.describe "Manager approval", type: :system do
  let(:employee) { create(:user, :employee, email: "emma@example.com") }
  let(:manager)  { create(:user, :manager,  email: "mark@example.com", name: "Mark Manager") }
  let(:gauge) do
    create(:gauge, name: "2026 Electricity", created_by: employee,
                   starts_on: Date.new(2026, 1, 1), ends_on: Date.new(2026, 12, 31), time_unit: :monthly)
  end

  def sign_in_as(user)
    visit new_user_session_path
    fill_in "Email", with: user.email
    fill_in "Password", with: "password"
    click_button "Sign in"
  end

  # Create frame for single *pending* row, keyed by the period's first date.
  def period_frame(date)
    "#period_#{gauge.id}_#{date.iso8601}"
  end

  it "lets a manager approve a pending reading, locking the row and bumping the counter without a reload" do
    create(:reading, gauge: gauge, entered_by: employee, period_start: Date.new(2026, 3, 1), value: 42)
    sign_in_as(manager)
    visit gauge_path(gauge)

    expect(page).to have_content("0 of 12 approved")

    within period_frame(Date.new(2026, 3, 1)) do
      click_button "Approve"
    end

    # The row is now approved and the counter has increased.
    expect(page).to have_content("Approved")
    expect(page).to have_content("by Mark Manager")
    expect(page).to have_content("1 of 12 approved")
    expect(page).to have_no_button("Approve")
    expect(page).to have_current_path(gauge_path(gauge))
  end

  it "offers no approve button on an already-approved reading" do
    create(:reading, :approved, gauge: gauge, entered_by: employee,
                                period_start: Date.new(2026, 3, 1), value: 42)
    sign_in_as(manager)
    visit gauge_path(gauge)

    expect(page).to have_content("Approved")
    expect(page).to have_no_button("Approve")
  end

  it "shows an employee no approve control on their own gauge" do
    create(:reading, gauge: gauge, entered_by: employee, period_start: Date.new(2026, 3, 1), value: 42)
    sign_in_as(employee)
    visit gauge_path(gauge)

    within period_frame(Date.new(2026, 3, 1)) do
      expect(page).to have_link("Edit")
      expect(page).to have_no_button("Approve")
    end
  end
end
