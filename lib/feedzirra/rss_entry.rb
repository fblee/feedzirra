module Feedzirra
  class RSSEntry
    include SAXMachine
    include FeedEntryUtilities
    element :title
    element :link, :as => :url

    element :guid

    element :"dc:creator", :as => :author
    element :"content:encoded", :as => :content
    element :description, :as => :summary

    element :pubDate, :as => :published
    element :"dc:date", :as => :published
    elements :category, :as => :categories

    # TODO: wtf... sometimes type="image/jpeg", sometimes medium="image", what are we to do?
    element :"media:content", :as => :image, :value => :url
  end
end