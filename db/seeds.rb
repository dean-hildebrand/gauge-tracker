# Two employees, one manager, and two gauges — each gauge owned by a different
# employee. The first gauge shows all three reading states (approved, pending,
# not entered) on first sign-in; the second, owned by the *other* employee,
# shows a truncated first period and lets you verify that an employee can only
# add/edit readings on gauges they created. Readings are entered by the owning
# employee and approved by the manager, mirroring the two-person workflow.

# Users
employee = User.find_or_create_by!(email: "employee@example.com") do |user|
  user.password = "password"
  user.name = "Emma Employee"
  user.role = :employee
end

employee2 = User.find_or_create_by!(email: "employee2@example.com") do |user|
  user.password = "password"
  user.name = "Emily Employee"
  user.role = :employee
end

manager = User.find_or_create_by!(email: "manager@example.com") do |user|
  user.password = "password"
  user.name = "Mark Manager"
  user.role = :manager
end

# Gauge 1 — owned by Emma. Full 2026 calendar year, monthly: 12 clean periods.
# Jan–Mar approved, Apr–May pending, Jun onward not entered.
electricity = Gauge.find_or_create_by!(name: "2026 Electricity") do |gauge|
  gauge.created_by = employee
  gauge.starts_on  = Date.new(2026, 1, 1)
  gauge.ends_on    = Date.new(2026, 12, 31)
  gauge.unit       = "kWh"
  gauge.time_unit  = :monthly
end

if electricity.readings.none?
  electricity.periods.each_with_index do |period, index|
    # Jun onward (index >= 5) stays empty so the "not entered" state is visible.
    next if index >= 5

    reading = electricity.readings.create!(
      entered_by:   employee,
      period_start: period.first,
      value:        1000 + (index * 85)
    )

    # Jan–Mar (index 0–2) approved; Apr–May (index 3–4) left pending.
    reading.approve!(manager) if index <= 2
  end
end

# Gauge 2 — owned by Emily (the *other* employee). Starts mid-month, monthly:
# makes the truncated head period (14 Mar – 31 Mar) visible, and lets you sign
# in as Emma to confirm she cannot add/edit readings on a gauge she doesn't own.
Gauge.find_or_create_by!(name: "Water — Q2 (mid-month start)") do |gauge|
  gauge.created_by = employee2
  gauge.starts_on  = Date.new(2026, 3, 14)
  gauge.ends_on    = Date.new(2026, 6, 20)
  gauge.unit       = "m³"
  gauge.time_unit  = :monthly
end

puts "Seeded #{User.count} users and #{Gauge.count} gauges " \
     "(#{Reading.approved.count} approved, #{Reading.pending.count} pending readings)."
