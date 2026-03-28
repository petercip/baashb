# Seeds — BAASH-B reference club for local development
# Run with: bin/rails db:seed
# Safe to re-run (find_or_create_by! guards against duplicates)

puts "Seeding BAASH-B club…"

club = Club.find_or_create_by!(slug: "baashb") do |c|
  c.name          = "BAASH-B"
  c.contact_email = "ethan.ayer@gmail.com"
  c.primary_color = "#c8a96e"
  c.font_choice   = "Inter"
  c.custom_domain  = "baash-b.org"
end
puts "  Club: #{club.name} (slug: #{club.slug})"

# Organizers
Member.find_or_create_by!(club: club, email: "ethan.ayer@gmail.com") do |m|
  m.name     = "Ethan Ayer"
  m.role     = :organizer
  m.status   = :active
  m.password = SecureRandom.hex(16)
  m.bio      = "BAASH-B Chairman. US National Team, Harvard, Cambridge, Andover."
end

Member.find_or_create_by!(club: club, email: "peter.cipollone@gmail.com") do |m|
  m.name     = "Pete Cipollone"
  m.role     = :organizer
  m.status   = :active
  m.password = SecureRandom.hex(16)
  m.bio      = "BAASH-B Board. Olympic Champion, Berkeley, St. Joseph's Prep."
end

puts "\nDone!"
puts "Visit http://baashb.lvh.me:3000"
puts "Sign in with gmail and use the organizer dashboard to add members, create events, and more."
