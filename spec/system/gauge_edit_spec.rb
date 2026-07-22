require "rails_helper"

RSpec.describe "Gauge editing", type: :system do
  let(:creator)     { create(:user, :employee, email: "emma@example.com") }
  let(:other_employee) { create(:user, :employee, email: "eric@example.com") }
  let(:manager)     { create(:user, :manager,  email: "mark@example.com") }

  def sign_in_as(user)
    visit new_user_session_path
    fill_in "Email", with: user.email
    fill_in "Password", with: "password"
    click_button "Sign in"
  end

  it "lets the creator edit their gauge from the detail page" do
    gauge = create(:gauge, name: "2026 Electricity", created_by: creator)

    sign_in_as(creator)
    visit gauge_path(gauge)
    click_link "Edit gauge"

    fill_in "Name", with: "2026 Power"
    click_button "Update gauge"

    expect(page).to have_current_path(gauge_path(gauge))
    expect(page).to have_content("Gauge updated successfully.")
    expect(page).to have_content("2026 Power")
    expect(gauge.reload.name).to eq("2026 Power")
  end

  it "does not show the edit link to a non-creator" do
    gauge = create(:gauge, name: "2026 Electricity", created_by: creator)

    sign_in_as(other_employee)
    visit gauge_path(gauge)

    expect(page).not_to have_link("Edit gauge")
  end

  it "lets a manager view a gauge's detail page without an edit link" do
    gauge = create(:gauge, name: "2026 Electricity", created_by: creator)

    sign_in_as(manager)
    visit gauge_path(gauge)

    expect(page).to have_current_path(gauge_path(gauge))
    expect(page).to have_content("2026 Electricity")
    expect(page).not_to have_link("Edit gauge")
  end

  it "refuses another employee the edit form with a redirect" do
    gauge = create(:gauge, created_by: creator)

    sign_in_as(other_employee)
    visit edit_gauge_path(gauge)

    expect(page).to have_current_path(root_path)
    expect(page).to have_content("You can only edit gauges you created.")
  end

  it "refuses a manager the edit form with a redirect and alert" do
    gauge = create(:gauge, created_by: creator)

    sign_in_as(manager)
    visit edit_gauge_path(gauge)

    expect(page).to have_current_path(root_path)
    expect(page).to have_content("Only employees can do that.")
  end
end
