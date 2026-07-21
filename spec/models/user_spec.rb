require "rails_helper"

RSpec.describe User, type: :model do
  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }
    it "requires a password on new records" do
      expect(build(:user, password: nil)).not_to be_valid
    end

    it "requires a unique email, case-insensitively" do
      create(:user, email: "dup@example.com")
      duplicate = build(:user, email: "DUP@example.com")

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:email]).to be_present
    end
  end

  describe "roles" do
    it { is_expected.to define_enum_for(:role).with_values(employee: 0, manager: 1) }

    it "builds each role via factory traits" do
      expect(create(:user, :employee)).to be_employee
      expect(create(:user, :manager)).to be_manager
    end
  end
end
