# Seeds — BAASH-B reference club for local development
# Run with: bin/rails db:seed
# Safe to re-run (find_or_create_by! guards against duplicates)

puts "Seeding BAASH-B club…"

club = Club.find_or_create_by!(slug: "baashb") do |c|
  c.name          = "BAASH-B"
  c.contact_email = "events@baash-b.org"
  c.primary_color = "#c8a96e"
  c.font_choice   = "Inter"
end
puts "  Club: #{club.name} (slug: #{club.slug})"

# Organizer
organizer = Member.find_or_create_by!(club: club, email: "organizer@example.com") do |m|
  m.name   = "Alice Chen"
  m.role   = :organizer
  m.status = :active
end
puts "  Organizer: #{organizer.name} <#{organizer.email}>"

# Members
[
  { name: "Bob Park",    email: "bob@example.com" },
  { name: "Carol Davis", email: "carol@example.com" },
  { name: "David Kim",   email: "david@example.com" }
].each do |attrs|
  m = Member.find_or_create_by!(club: club, email: attrs[:email]) do |member|
    member.name   = attrs[:name]
    member.role   = :member
    member.status = :active
  end
  puts "  Member: #{m.name} <#{m.email}>"
end

# Events
spring_dinner = Event.find_or_create_by!(club: club, name: "Spring Rowing Dinner 2026") do |e|
  e.description = "Join us for our annual spring dinner at The Boathouse. Dinner, drinks, and stories from the water."
  e.starts_at   = Time.zone.parse("2026-04-12 19:00:00")
  e.ends_at     = Time.zone.parse("2026-04-12 22:00:00")
  e.venue       = "The Boathouse, San Francisco"
  e.capacity    = 40
  e.price_cents = 0
  e.status      = :published
end
puts "  Event: #{spring_dinner.name} (slug: #{spring_dinner.slug})"

alumni_mixer = Event.find_or_create_by!(club: club, name: "Alumni Mixer Summer 2026") do |e|
  e.description = "Casual mixer for alumni. All eras welcome."
  e.starts_at   = Time.zone.parse("2026-07-18 18:30:00")
  e.venue       = "Fort Mason, San Francisco"
  e.capacity    = 60
  e.price_cents = 0
  e.status      = :published
end
puts "  Event: #{alumni_mixer.name} (slug: #{alumni_mixer.slug})"

puts "\nDone!"
puts "Visit http://baashb.lvh.me:3000"
puts "Sign in with any seeded email — magic link appears in letter_opener (open tmp/letter_opener)"
