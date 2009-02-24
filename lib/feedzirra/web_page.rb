module Feedzirra
  class WebPage
    include SAXMachine
    include FeedUtilities
    element :title # not essential; helpful for debugging
    element :link, :as => :feed_url, :value => :href, :with => {:rel => 'alternate', :type => "application/rss+xml"}
  end
end