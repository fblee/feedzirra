module Feedzirra
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

    def self.able_to_parse?(xml)
      xml =~ /\<rss|rdf/
    end
  end
end