require "rails_helper"

RSpec.describe "Reading entry", type: :system do
  let(:employee) { create(:user, :employee, email: "emma@example.com") }
  let(:other)    { create(:user, :employee, email: "eve@example.com") }
  let(:manager)  { create(:user, :manager,  email: "mark@example.com") }
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

  # Frame that wraps a single period row, keyed by the period's first date.
  def period_frame(date)
    "#period_#{gauge.id}_#{date.iso8601}"
  end

  it "lets an employee enter a value inline without a page reload" do
    sign_in_as(employee)
    visit gauge_path(gauge)

    within period_frame(Date.new(2026, 3, 1)) do
      click_link "Add reading"
      fill_in "reading_value", with: "123.5"
      click_button "Save"
    end

    within period_frame(Date.new(2026, 3, 1)) do
      expect(page).to have_content("123.5")
      expect(page).to have_content("Pending")
      expect(page).to have_link("Edit")
      expect(page).not_to have_button("Save")
    end
    expect(page).to have_current_path(gauge_path(gauge))
    expect(gauge.readings.find_by(period_start: Date.new(2026, 3, 1)).value).to eq(123.5)
  end

  it "lets an employee edit a pending value inline" do
    create(:reading, gauge: gauge, entered_by: employee, period_start: Date.new(2026, 4, 1), value: 50)
    sign_in_as(employee)
    visit gauge_path(gauge)

    within period_frame(Date.new(2026, 4, 1)) do
      click_link "Edit"
      fill_in "reading_value", with: "75"
      click_button "Save"
    end

    within period_frame(Date.new(2026, 4, 1)) do
      expect(page).to have_content("75")
      expect(page).not_to have_button("Save")
    end
  end

  it "re-renders the form with errors inside the frame on an invalid value" do
    sign_in_as(employee)
    visit gauge_path(gauge)

    within period_frame(Date.new(2026, 3, 1)) do
      click_link "Add reading"
      fill_in "reading_value", with: ""
      click_button "Save"

      expect(page).to have_content("can't be blank")
      expect(page).to have_button("Save")
    end
    expect(gauge.readings).to be_empty
  end

  # A manager can approve while the employee sits on a stale page: both the Edit
  # link and an open edit form must fail loudly and redraw the row.
  it "refuses an edit click on a row approved since the page was rendered" do
    reading = create(:reading, gauge: gauge, entered_by: employee,
                               period_start: Date.new(2026, 4, 1), value: 50)
    sign_in_as(employee)
    visit gauge_path(gauge)

    reading.approve!(manager)

    within(period_frame(Date.new(2026, 4, 1))) { click_link "Edit" }

    expect(page).to have_content("That reading was already approved and can no longer be edited.")
    expect(page).to have_content("Approved")
    expect(page).to have_no_selector(period_frame(Date.new(2026, 4, 1)))
    expect(page).to have_content("1 of 12 approved")
  end

  it "refuses a save when the reading is approved mid-edit" do
    reading = create(:reading, gauge: gauge, entered_by: employee,
                               period_start: Date.new(2026, 4, 1), value: 50)
    sign_in_as(employee)
    visit gauge_path(gauge)

    within period_frame(Date.new(2026, 4, 1)) do
      click_link "Edit"
      fill_in "reading_value", with: "75"
    end

    reading.approve!(manager)

    within(period_frame(Date.new(2026, 4, 1))) { click_button "Save" }

    expect(page).to have_content("That reading was already approved and can no longer be edited.")
    expect(page).to have_content("Approved")
    expect(page).to have_no_button("Save")
    expect(reading.reload.value).to eq(50)
  end

  it "shows an employee read-only rows on a gauge they did not create" do
    create(:reading, gauge: gauge, entered_by: employee, period_start: Date.new(2026, 5, 1), value: 10)
    sign_in_as(other)
    visit gauge_path(gauge)

    within period_frame(Date.new(2026, 5, 1)) do
      expect(page).to have_content("Pending")
      expect(page).to have_no_link("Edit")
    end
    # Not the gauge's creator, so no entry affordance at all.
    expect(page).to have_no_link("Add reading")
  end

  it "shows a manager read-only rows with no entry controls" do
    create(:reading, gauge: gauge, entered_by: employee, period_start: Date.new(2026, 5, 1), value: 10)
    sign_in_as(manager)
    visit gauge_path(gauge)

    expect(page).to have_content("2026 Electricity")
    expect(page).to have_no_link("Edit")
    expect(page).to have_no_link("Add reading")
  end
end
