require "./echonest.rb"

def display_results(results_list)
  results_list.each { |obj| puts obj.inspect }
end

#configuration
Echonest::Config.API_KEY = "PHZWVZCEHLNHCMDQH"
puts "\n*************************"
puts Echonest::Config.API_KEY
puts Echonest::Config.USER_AGENT
puts


#Song Tests
radiohead = Echonest::Artist::Artist.new("radiohead")
karma_police = Echonest::Song::Song.new("SOASNLP131677142F0", nil, nil, [:audio_summary])
#puts karma_police.inspect
#puts
airbag = Echonest::Song::Song.new("SOASNLP131677142F0", nil, nil)
#puts airbag.inspect
#puts airbag.get_audio_summary

#display_results(radiohead.get_songs)

#Artist Tests
#radiohead = Echonest::Artist::Artist.new("radiohead")
#radiohead = Echonest::Artist::Artist.new("radiohead", nil, buckets=[:doc_counts,:reviews])
#puts radiohead.inspect

#test profile
# puts radiohead.id 
# puts radiohead.name


#test buckets
# puts radiohead.doc_counts

#test getters
#puts radiohead.get_similar_artists
#results_list = radiohead.get_similar_artists(buckets: [:hotttnesss, :familiarity])
#display_results(results_list)

#puts  radiohead.get_terms
#puts radiohead.get_hotttnesss
#puts radiohead.get_familiarity
#puts radiohead.get_documents("blogs")
#puts radiohead.get_songs
#puts
#test search
#search_no_bucket =  Echonest::Artist::search(name: "radiohead", results: 15)
#search_with_bucket =   Echonest::Artist::search(name: "radiohead", buckets: [:hotttnesss, :familiarity])
#display_results(search_no_bucket)
#puts
#display_results(search_with_bucket)
#puts
# test top_terms and top_hottt
#puts Echonest::Artist::get_top_terms
# top_hottt_no_bucket = Echonest::Artist::get_top_hottt
# top_hottt_with_bucket = Echonest::Artist::get_top_hottt(buckets: [:hotttnesss, :familiarity])

# display_results(top_hottt_no_bucket)
# puts
# display_results(top_hottt_with_bucket)

puts "*************************\n"
