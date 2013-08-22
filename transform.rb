#!/usr/bin/env ruby

# Transform group voting data from belowtheline into a form that can go into the R statistics
# package to do some multidimensional scaling magic as a way to try to visualise the "closeness"
# of different parties

# TODO:
# 1. Currently we will get different results depending on the number of candidates in a different group.
# So, for instance if group A preferences group B first in the 4th spot and there are 4 members of group B
# it will have an average distance A<->B of 5.5. If there are less members in group B that number will be
# smaller. Maybe we should look at taking the minimum distance instead (rather than the average)
# 2. We're currently ignoring independent candidates. We could include them by lumping candidates together
# by group rather than party. We're currently effectively doing this with the Lib/Nat coalition. We could
# do this with the independents as well
# 3. Combine data from different states
# 4. Don't entirely ignore parties that have not submitted a ticket (because we can still get information
# from how the other parties preference that party)
# 5. Handle situation where parties submit more than one ticket. At the moment we're just looking at
# the first ticket

require "json"

def party(person_label)
  person = JSON.load(File.open("belowtheline/data/people/#{person_label}.json"))
  person["party"] || "ind"
end

# Average of an array
def average(a)
  # We can do this much more concisely
  s = 0
  a.each do |v|
    s += v
  end
  s.to_f / a.count
end

def group_info(group_file)
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

  puts "Don't currently support more than one ticket per group" if group["tickets"].count > 1
  # Just going to take the first ticket for the time being. We really should calculate the
  # scores for each ticket and then average them
  ticket = group["tickets"].first
  if ticket.nil?
    # No ticket was submitted to the AEC
    return {:party => group_party}
  end
  party_order = ticket.map{|t| party(t)}
  # Do coalition substitution
  party_order = party_order.map{|p| (p == "lib" || p == "nat") ? "coa" : p}
  party_scores = {}
  party_order.each_with_index do |party, i|
    party_scores[party] = (party_scores[party] || []).push(i)
  end
  average_party_scores = {}
  party_scores.each do |p, v|
    average_party_scores[p] = average(v)
  end
  # Tweak things so that its own party has a "distance" of 0
  average_party_scores_tweaked = {}
  raise "group_party #{group_party} couldn't be found" if average_party_scores[group_party].nil?
  average_party_scores.each do |p,v|
    average_party_scores_tweaked[p] = v - average_party_scores[group_party]
  end
  {:party => group_party, :distances => average_party_scores_tweaked}
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
  Dir.glob("belowtheline/data/groups/#{state}-*.json").each do |file|
    i = group_info(file)
    infos[i[:party]] = i[:distances]
  end

  parties = infos.keys.uniq.sort.reject{|p| p == "ind" || infos[p].nil?}

  matrix = party_hash_to_array(infos, parties).map{|h| party_hash_to_array(h, parties)}
  # Convert parties to full names
  parties_full_names = parties.map{|p| lookup_party_full_name(p)}

  write_distance_matrix("distance_#{state}.dat", parties_full_names, matrix)
end

["act", "nsw", "nt", "qld", "sa", "tas", "vic", "wa"].each{|s| process_state(s)}
