require "rails_helper"

RSpec.describe Reading, type: :model do
  let(:employee) { create(:user, :employee) }
  let(:manager)  { create(:user, :manager) }
  let(:gauge)    { create(:gauge, created_by: employee) }

  def reading(attrs = {})
    create(:reading, { gauge: gauge, entered_by: employee }.merge(attrs))
  end

  describe "#approve!" do
    it "records who approved it and when, and marks it approved" do
      r = reading(value: 10)

      r.approve!(manager)

      expect(r).to be_approved
      expect(r.approved_by).to eq(manager)
      expect(r.approved_at).to be_present
    end

    it "raises ImmutableError on a second approval, leaving the first approver intact" do
      r = reading
      r.approve!(manager)
      other_manager = create(:user, :manager)

      expect { r.approve!(other_manager) }.to raise_error(Reading::ImmutableError)
      expect(r.reload.approved_by).to eq(manager)
    end
  end

  describe "immutability guard" do
    it "allows editing a pending reading" do
      r = reading(value: 10)

      expect(r.update(value: 20)).to be(true)
      expect(r.reload.value).to eq(20)
    end

    it "refuses to update an approved reading" do
      r = reading(value: 10)
      r.approve!(manager)

      expect(r.update(value: 999)).to be(false)
      expect(r.reload.value).to eq(10)
      expect(r.errors[:base]).to include("Approved readings cannot be modified")
    end
  end
end
