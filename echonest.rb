#Ruby client for Echonest API
require "json"
require "net/http"

#todo: add documents methods
module Echonest
  VERSION = "v.1"
  BASE_URL =  'http://developer.echonest.com/api'

  module Config
    @API_VERSION = 'v4'
    @API_KEY = ''
    @USER_AGENT = "RbEchonest/#{Echonest::VERSION}"
    class << self
      attr_accessor :API_KEY, :API_VERSION
      attr_reader :USER_AGENT
    end
  end
  
  module Utils
    class EchonestAPIError < StandardError
    end
    class EchonestClientError < StandardError
    end

    def Utils.call_api(sub_module, method, params, post = false)
      url = URI("%s/%s/%s/%s?" % [BASE_URL, Config.API_VERSION, sub_module, method])
      params[:api_key] = Config.API_KEY
      if params[:format] == nil
        params[:format] = "json"
      end
     
      url.query = URI.encode_www_form(params)
      res = Net::HTTP.get_response(url)  
      json_res = JSON::parse(res.body)

      if json_res["response"]["status"]["code"] != 0
        raise EchonestAPIError, "Echonest API Error code: #{json_res["response"]["status"]["code"]} \n  message: #{json_res["response"]["status"]["message"]} "
      end
      
      json_res["response"]    
    end
  end
  class BaseApi
    def initialize()
    end
  end
  
  module Artist
    SUB_MODULE = "artist"
     
    #Search for artist
    def Artist.search(options = {})
      accepted_params = [:results, :limit, :sort, :name, :description, :style, :mood, :rank_type, :fuzzy_match, :max_familiarity, :min_familiarity, :max_hotttnesss, :min_hotttnesss, :artist_start_year_before, :artist_end_year_before, :artist_start_year_after, :artist_end_year_after, :start, :bucket]
      params = {}

      #buckets is unpluralized 
      if options.has_key?(:buckets)
        options[:bucket] = options[:buckets]
        options.delete(:buckets)
      end

      options.each do |param, val|
        if accepted_params.find_index(param) != nil
          params[param] = val
        else
          raise "#{param} is not a valid search parameter"
        end
      end
        
      artists_json = Utils.call_api(SUB_MODULE,"search", params)
      results = []

      if artists_json.has_key?('artists')
        if !params.has_key?(:bucket)
          artists_json['artists'].each do |artist|
            results.push(Artist.new(name = artist["name"], id = artist["id"],[]))
          end
        else
          artists_json['artists'].each do |artist|
            tmp_artist = Artist.new(name = artist["name"], id = artist["id"],[])
            params[:bucket].each { |bucket| tmp_artist.instance_variable_set("@#{bucket}", artist[bucket.to_s]) }
            results.push(tmp_artist)
          end          
        end
      end
      results
    end
   
    def Artist.get_top_terms(results = 15)
      res_json = Utils.call_api(SUB_MODULE, "top_terms", { results: results } )
      res_json["terms"]
    end

    def Artist.get_top_hottt(options = {})
      accepted_params = [:start, :results,:bucket,:limit]
      params = {}
      
      #remove plural #'buckets'
      if options.has_key?(:buckets)
        options[:bucket] = options[:buckets]
        options.delete(:buckets)
      end

      options.each do |param, val|
        if accepted_params.find_index(param) != nil
          params[param] = val
        else
          raise "#{param} is not a valid search parameter"
        end
      end
      
      artists_json = Utils.call_api(SUB_MODULE, "top_hottt", params)
      results = []
      #convert json into artist objects
      if artists_json.has_key?('artists')
        if !params.has_key?(:bucket)
          artists_json['artists'].each do |artist|
            results.push(Artist.new(name = artist["name"], id = artist["id"],[]))
          end
        else
          artists_json['artists'].each do |artist|
            tmp_artist = Artist.new(name = artist["name"], id = artist["id"],[])
            params[:bucket].each { |bucket| tmp_artist.instance_variable_set("@#{bucket}", artist[bucket.to_s]) }
            results.push(tmp_artist)
          end          
        end
      end
      results
    end
    
    class Artist < Echonest::BaseApi

      attr_accessor :name, :id, :biographies, :blogs, :doc_counts, :familiarity, :hotttnesss, :images, :news, :reviews, :urls, :video, :similar_artists, :terms, :twitter,:songs
      
      def initialize(name = nil, id = nil, buckets = [])
        super()
        if name == nil && id == nil
          raise "Artist-Id or Artist-Name required"
        end
        # no profile required 
        if name != nil && id != nil && buckets.size == 0 
          @id = id
          @name = name
        # profile artist
        else 
          params = {} 
          if buckets.size > 0
            params[:bucket] = buckets
          end

          if id != nil 
            params[:id] = id
            @id = id
          elsif name != nil 
            params[:name] = name
          end
          
          profile_json = Utils.call_api(SUB_MODULE, "profile", params)
          
          @id = profile_json["artist"]["id"]
          @name =  profile_json["artist"]["name"] 
          
          buckets.each { |bucket| instance_variable_set("@#{bucket}",profile_json["artist"][bucket.to_s]) }
        end
        
      end

      def get_attr(method, params)
        params[:id] = @id
        Utils.call_api(SUB_MODULE, method, params)
      end

      private :get_attr

      def get_terms(sort = 'frequency')
        if @terms == nil
          res_json = get_attr("terms", { sort: sort } )
          if res_json.has_key?("terms") && res_json["terms"].size > 0
            @terms = res_json["terms"]
          else
            @terms = []
          end
        end
      end

      
      #accepts parameters as hash
      def get_similar_artists(options={})
        accepted_params = [:results, :min_results, :limit, :sort, :style, :mood, :max_familiarity, :min_familiarity, :max_hotttnesss, :min_hotttnesss, :artist_start_year_before, :artist_end_year_before, :artist_start_year_after, :artist_end_year_after, :start, :bucket, :seed_catalog]
        params = {}

        #buckets is unpluralized 
        if options.has_key?(:buckets)
          options[:bucket] = options[:buckets]
          options.delete(:buckets)
        end
        
        options.each do |param, val|
          if accepted_params.find_index(param)
            params[param] = val
          else
            raise "#{param} is not a valid search parameter"
          end  
        end
        
        res_json = get_attr("similar", params)          
        if res_json.has_key?("artists") && res_json["artists"].size > 0
          @similar_artists = []
          
          #convert json into artist objects
          if params.has_key?(:bucket)
            res_json['artists'].each do |artist|
              tmp_artist = Artist.new(name = artist["name"], id = artist["id"],[])

              params[:bucket].each { |bucket| tmp_artist.instance_variable_set("@#{bucket}", artist[bucket.to_s]) }
              @similar_artists.push(tmp_artist)
            end 
          else
            res_json['artists'].each { |artist| @similar_artists.push(Artist.new(name = artist["name"], id = artist["id"],[])) }
          end
          @similar_artists 
        end
      end
      
      # Returns hash of artist's websites 
      # format- {websiteName => address}
      def get_urls
        if @urls == nil
          @urls = get_attr("urls", {})["urls"]
        end
        @urls
      end
      
      #Returns hash of blogs/news about the artist from web. 
      def get_documents(type, results = 15, start = 0, high_relevance = false)
        if type != "blogs" && type != "news" 
          raise "#{type} is not a valid document type"
        end
   
        params = { results: results, start: start, high_relevance: high_relevance }
        res_json = get_attr(type, params)
        instance_variable_set("@#{type}", res_json["blogs"])
      end

      def get_songs(results = 15, start = 0)
        if @songs == nil || results != 15  || start > 0
          @songs = []          
          #setup params
          params = { results: results, start: start}

          song_json = get_attr("songs", params)

          #convert json to song-objects
          if song_json.has_key?('songs') && song_json['songs'].size > 0
            song_json['songs'].each do |song|
              song = Song::Song.new(id = song['id'], title = song['title'],artist_id = @id,[])
              @songs.push(song)
            end
          else
            @songs = []
          end
        end
        @songs
      end

      def get_twitter
        if @twitter == nil
          artist_json = get_attr("twitter",{})["artist"]
          if artist_json.has_key?("twitter")
            @twitter = artist_json["twitter"]            
          else
            @twitter = nil
          end
        end
      end
      
      def get_hotttnesss(type = "overall")
        artist_json = get_attr("hotttnesss", { type: type })["artist"]
        @hotttnesss = artist_json["hotttnesss"].to_f
      end
      
      def get_familiarity
        if @familiarity == nil
          artist_json = get_attr("familiarity", {})["artist"]
          @familiarity = artist_json["familiarity"].to_f
        end
        @familiarity
      end

      def inspect
        instance_variables.reduce("Echonest::Artist::Artist ") do |repr, var| 
          val = instance_variable_get(var)
          "#{repr} #{var}=#{val}" 
        end
      end

      def get_biographies
      end
      
      def get_reviews
      end

      def get_images(results = 15, start = 0, license = nil)
      end

    
    end
    
  end
  
  module Song
    SUB_MODULE = "song"
    
    def Song.search(options = {})
    end

    class Song < Echonest::BaseApi
      
      attr_accessor :artist_id, :title, :id, :audio_summary, :song_hotttnesss, :artist_location, :artist

      # Only profiles songs initialized with buckets
      def initialize(id, title = nil, artist_id = nil,buckets = [])
        super()
        @id  = id
        @title = title 
        @artist_id = artist_id 
        # profile song
        if buckets.size > 0 
          params = { id: @id, bucket: buckets } 
          
          res_json = Utils.call_api(SUB_MODULE, "profile", params)
          song_json = res_json["songs"][0]
          @title = @title != nil ? @title : song_json["title"]
          @artist_id = song_json["artist_id"] 
          buckets.each { |bucket| instance_variable_set("@#{bucket}", song_json[bucket.to_s]) }
        end
      end
 
      def get_attr(method, params)
        params[:id] = @id
        Utils.call_api(SUB_MODULE, method, params)
      end

      private :get_attr

      
      def get_audio_summary
        params = { id: @id, bucket: [:audio_summary] } 
        res_json = Utils.call_api(SUB_MODULE, "profile", params)
        song_json = res_json["songs"][0]
        @audio_summary = song_json["audio_summary"]
      end
      
      
      def inspect
        instance_variables.reduce("Echonest::Song::Song ") do |repr, var| 
          val = instance_variable_get(var)
          "#{repr} #{var}=#{val}" 
        end
      end
    end
  end
  
end

  
