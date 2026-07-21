# Users
User.find_or_create_by!(email: "employee@example.com") do |user|
  user.password = "password"
  user.name = "Emma Employee"
  user.role = :employee
end

User.find_or_create_by!(email: "manager@example.com") do |user|
  user.password = "password"
  user.name = "Mark Manager"
  user.role = :manager
end
