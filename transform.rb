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

def group_info(group_label)
  group = JSON.load(File.open("belowtheline/data/groups/#{group_label}.json"))
  raise "Can't currently handle multiple parties in a group" if group["parties"].count > 1
  group_party = group["parties"].first

  raise "Don't currently support more than one ticket per group" if group["tickets"].count > 1
  ticket = group["tickets"].first

  party_order = ticket.map{|t| party(t)}
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

p group_info("nsw-A")