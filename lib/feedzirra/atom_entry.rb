module Feedzirra
  class AtomEntry
    include SAXMachine
    include FeedEntryUtilities
    element :title
    element :link, :as => :url, :value => :href, :with => {:type => "text/html", :rel => "alternate"}
    element :name, :as => :author

    # fix feed 22
    element :guid
    element :content
    element :summary
    element :published
    element :created, :as => :published
    element :"media:content", :as => :image, :value => :url
    elements :category, :as => :categories, :value => :term
  end
end