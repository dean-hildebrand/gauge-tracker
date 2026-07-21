require "rails_helper"

RSpec.describe "Authentication", type: :system do
  let(:password) { "password" }
  let!(:employee) { create(:user, :employee, email: "emma@example.com", password: password) }

  def sign_in_as(email, pass)
    visit new_user_session_path
    fill_in "Email", with: email
    fill_in "Password", with: pass
    click_button "Sign in"
  end

  it "redirects an unauthenticated visitor to the sign-in page" do
    visit root_path

    expect(page).to have_current_path(new_user_session_path)
    expect(page).to have_content("Sign in")
  end

  it "signs in with valid credentials and lands on the gauge index" do
    sign_in_as("emma@example.com", password)

    expect(page).to have_current_path(root_path)
    expect(page).to have_content("Signed in successfully")
  end

  it "rejects invalid credentials and stays on the sign-in page" do
    sign_in_as("emma@example.com", "wrong-password")

    expect(page).to have_content("Invalid email or password.")
    expect(page).to have_button("Sign in")
  end

  it "signs the user out" do
    sign_in_as("emma@example.com", password)
    expect(page).to have_content("Signed in successfully")

    click_button "Logout"

    # after_sign_out_path_for sends us straight to sign-in, so the friendly
    # notice survives and there is no way back into the app.
    expect(page).to have_current_path(new_user_session_path)
    expect(page).to have_content("Signed out successfully")
    expect(page).not_to have_button("Logout")
  end
end
