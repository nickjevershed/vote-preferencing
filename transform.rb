#!/usr/bin/env ruby

# Transform group voting data from belowtheline into a form that can go into the R statistics
# package to do some multidimensional scaling magic as a way to try to visualise the "closeness"
# of different parties

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
  if group["parties"] == ["lib", "nat"]
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
  average_party_scores.each do |p,v|
    average_party_scores_tweaked[p] = v - average_party_scores[group_party]
  end
  {:party => group_party, :distances => average_party_scores_tweaked}
end

Dir.glob("belowtheline/data/groups/nsw-*.json").each do |file|
  p group_info(file)
end