require "rails_helper"

RSpec.describe "Gauge index", type: :system do
  let(:employee) { create(:user, :employee, email: "emma@example.com") }
  let(:manager)  { create(:user, :manager,  email: "mark@example.com") }

  def sign_in_as(user)
    visit new_user_session_path
    fill_in "Email", with: user.email
    fill_in "Password", with: "password"
    click_button "Sign in"
  end

  it "lists gauges for an employee, who also sees the new-gauge button" do
    create(:gauge, name: "2026 Electricity", created_by: employee)

    sign_in_as(employee)

    expect(page).to have_content("2026 Electricity")
    expect(page).to have_link("New gauge")
  end

  it "lists gauges for a manager, who does not see the new-gauge button" do
    create(:gauge, name: "2026 Electricity", created_by: employee)

    sign_in_as(manager)

    expect(page).to have_content("2026 Electricity")
    expect(page).not_to have_link("New gauge")
  end
end
