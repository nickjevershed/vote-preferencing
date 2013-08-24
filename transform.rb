#!/usr/bin/env ruby

# Transform group voting data from belowtheline into a form that can go into the R statistics
# package to do some multidimensional scaling magic as a way to try to visualise the "closeness"
# of different parties

# TODO:
# 1. We're currently ignoring independent candidates. We could include them by lumping candidates together
# by group rather than party. We're currently effectively doing this with the Lib/Nat coalition. We could
# do this with the independents as well
# 2. Combine data from different states
# 3. Don't entirely ignore parties that have not submitted a ticket (because we can still get information
# from how the other parties preference that party)
# 4. Handle situation where parties submit more than one ticket. At the moment we're just looking at
# the first ticket

require "json"

def party(person_label)
  person = JSON.load(File.open("belowtheline/data/people/#{person_label}.json"))
  person["party"] || "ind"
end

def lookup_tickets(group_file)
  group = JSON.load(File.open(group_file))
  # Special handling for coalition. We will treat them as one party
  if group["parties"] == ["lib", "nat"] || group["parties"] == ["lib"] || group["parties"] == ["nat"] ||
    group["parties"] == ["nat", "lib"]
      group_party = "coa"
  elsif group["parties"].count <= 1
    group_party = group["parties"].first
  else
    raise "Can't currently handle multiple parties in a group"
  end

  if group_party.nil?
    return {:party => "ind"}
  end

  tickets = group["tickets"]
  if tickets.empty?
    # No ticket was submitted to the AEC
    puts "INFO: No ticket was submitted in #{group_file}"
    return {:party => group_party}
  end
  {:party => group_party, :tickets => tickets}
end

def group_info(group_file, parties_to_ignore)
  a = lookup_tickets(group_file)
  if a[:tickets].nil?
    return {:party => a[:party]}
  end
  # Just going to take the first ticket for the time being. We really should calculate the
  # scores for each ticket and then average them
  puts "Don't currently support more than one ticket per group" if a[:tickets].count > 1
  ticket = a[:tickets].first
  group_party = a[:party]

  party_order = ticket.map{|t| party(t)}
  # Do coalition substitution
  party_order = party_order.map{|p| (p == "lib" || p == "nat") ? "coa" : p}
  # Remove parties that we want to ignore (no tickets and independents)
  party_order = party_order.reject{|p| parties_to_ignore.include?(p)}
  # Only keep the first instance of a party
  party_order2 = []
  party_order.each do |party|
    unless party_order2.include?(party)
      party_order2 << party
    end
  end
  party_scores = {}
  party_order2.each_with_index do |party, i|
    party_scores[party] = i
  end
  {:party => group_party, :distances => party_scores}
end

def party_hash_to_array(infos, parties)
  r = []
  parties.each do |party|
    r << infos[party]
  end
  r
end

def lookup_party_full_name(party_code)
  # Special handling for our "made up" party the coalition
  if party_code == "coa"
    "Coalition (Lib/Nat)"
  else
    party = JSON.load(File.open("belowtheline/data/parties/#{party_code}.json"))
    party["name"]
  end
end

def write_distance_matrix_as_csv(filename, parties_full_names, matrix)
  puts "Writing data to files #{filename}..."
  File.open(filename, "w") do |f|
    f << (['"Party"'].concat(parties_full_names.map{|p| '"' + p + '"'})).join(",") << "\n"
    index = 0
    matrix.each do |row|
      f << '"' << parties_full_names[index] << '",' << row.join(",") << "\n"
      index += 1
    end
  end
end

def write_distance_matrix(filename, parties_full_names, matrix)
  puts "Writing data to files #{filename}..."
  File.open(filename, "w") do |f|
    f << parties_full_names.map{|p| '"' + p + '"'}.join(" ") << "\n"
    index = 0
    matrix.each do |row|
      f << '"' << parties_full_names[index] << '" ' << row.join(" ") << "\n"
      index += 1
    end
  end
end

def process_state(state)
  infos = {}

  # Ignore independents and parties that have not submitted a ticket
  parties_to_ignore = Dir.glob("belowtheline/data/groups/#{state}-*.json").map{|file| lookup_tickets(file)}.
    select{|a| a[:tickets].nil?}.map{|a| a[:party]}.uniq

  Dir.glob("belowtheline/data/groups/#{state}-*.json").each do |file|
    i = group_info(file, parties_to_ignore)
    infos[i[:party]] = i[:distances] if i[:distances]
  end

  parties = infos.keys.uniq.sort

  matrix = party_hash_to_array(infos, parties).map{|h| party_hash_to_array(h, parties)}
  # Convert parties to full names
  parties_full_names = parties.map{|p| lookup_party_full_name(p)}

  write_distance_matrix("output/distance_#{state}.dat", parties_full_names, matrix)
  write_distance_matrix_as_csv("output/distance_#{state}.csv", parties_full_names, matrix)
end

["act", "nsw", "nt", "qld", "sa", "tas", "vic", "wa"].each{|s| process_state(s)}
