module Feedzirra
  
  module Parser
    # == Summary
    # Parser for dealing with RSS feeds.
    #
    # == Attributes
    # * title
    # * feed_url
    # * url
    # * entries
    class RSS
      include SAXMachine
      include FeedUtilities
      element :title
      element :link, :as => :url
      elements :item, :as => :entries, :class => RSSEntry

      # parse the subtitle and description, so we can use whatever we have!
      element :subtitle
      element :description, :as => :feed_description
      
      attr_accessor :feed_url

      def description
          self.feed_description || self.subtitle
      end

      def self.able_to_parse?(xml) #:nodoc:
        xml =~ /\<rss|rdf/
      end
    end

  end
  
end