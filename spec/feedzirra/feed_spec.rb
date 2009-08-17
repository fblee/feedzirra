require File.dirname(__FILE__) + '/../spec_helper'

describe Feedzirra::Feed do
  describe "#parse" do # many of these tests are redundant with the specific feed type tests, but I put them here for completeness
    context "when there's an available parser" do
      it "should parse an rdf feed" do
        feed = Feedzirra::Feed.parse(sample_rdf_feed)
        feed.title.should == "HREF Considered Harmful"
        feed.entries.first.published.to_s.should == "Tue Sep 02 19:50:07 UTC 2008"
        feed.entries.size.should == 10
      end

      it "should parse an rss feed" do
        feed = Feedzirra::Feed.parse(sample_rss_feed)
        feed.title.should == "Tender Lovemaking"
        feed.entries.first.published.to_s.should == "Thu Dec 04 17:17:49 UTC 2008"
        feed.entries.size.should == 10
      end

      it "should parse an atom feed" do
        feed = Feedzirra::Feed.parse(sample_atom_feed)
        feed.title.should == "Amazon Web Services Blog"
        feed.entries.first.published.to_s.should == "Fri Jan 16 18:21:00 UTC 2009"
        feed.entries.size.should == 10
      end

      it "should parse an feedburner atom feed" do
        feed = Feedzirra::Feed.parse(sample_feedburner_atom_feed)
        feed.title.should == "Paul Dix Explains Nothing"
        feed.entries.first.published.to_s.should == "Thu Jan 22 15:50:22 UTC 2009"
        feed.entries.size.should == 5
      end

      it "should parse a web page" do
        real_bbc_rss_url = "http://newsrss.bbc.co.uk/rss/newsonline_uk_edition/front_page/rss.xml"
        feed = Feedzirra::WebPage.parse(sample_web_page)
        feed.feed_url.should == real_bbc_rss_url

        real_avc_url = 'http://feeds.feedburner.com/AVc'
        feed = Feedzirra::WebPage.parse(sample_web_page2)
        feed.feed_url.should == real_avc_url

      end

      it "should parse BBC news and get the RSS feed" do
        bbc_web_url = 'http://news.bbc.co.uk/'
        real_bbc_rss_url = "http://newsrss.bbc.co.uk/rss/newsonline_uk_edition/front_page/rss.xml"
        feed = Feedzirra::Feed.fetch_and_parse(bbc_web_url)
        feed.title.should == 'BBC News | News Front Page | UK Edition'
        feed.feed_url.should == real_bbc_rss_url
        feed.entries.size.should > 0

        real_avc_url = 'http://feeds.feedburner.com/AVc'
        # for this test, avc.com is where you visit, but the feed itself reports its
        # canonical location as www.avc.com/a_vc/ which is fine, but means this test looks
        # a bit weird!
        avc_web_url = 'http://www.avc.com/'
        avc_home_url = 'http://www.avc.com/a_vc/'
        feed = Feedzirra::Feed.fetch_and_parse(avc_web_url)
        feed.feed_url.should == real_avc_url
        feed.url.should == avc_home_url
        feed.entries.size.should > 0
      end

      it "should extract image URLs" do
        feed = Feedzirra::Feed.parse(sample_rss_with_images)
        feed.entries.size.should > 0
        feed.entries[0].image.should == 'http://www.gravatar.com/avatar/5c6727e573b7be20dea6a6880856a888?s=96&#38;d=identicon'
      end

      it "should determine parser correctly" do
        feed = Feedzirra::Feed.parse(sample_problematic_parser_detection)
        feed.entries.size.should > 0
        feed = Feedzirra::Feed.fetch_and_parse('http://www.independent.co.uk/news/world/rss')
        feed.entries.size.should > 0
        #puts feed.title
      end
    end
    
    context "when there's no available parser" do
      it "raises Feedzirra::NoParserAvailable" do
        proc {
          Feedzirra::Feed.parse("I'm an invalid feed")
        }.should raise_error(Feedzirra::NoParserAvailable)
      end      
    end
    
    it "should parse an feedburner rss feed" do
      feed = Feedzirra::Feed.parse(sample_rss_feed_burner_feed)
      feed.title.should == "Sam Harris: Author, Philosopher, Essayist, Atheist"
      feed.entries.first.published.to_s.should == "Tue Jan 13 17:20:28 UTC 2009"
      feed.entries.size.should == 10
    end
  end
  
  describe "#determine_feed_parser_for_xml" do
    it "should return the Feedzirra::Atom class for an atom feed" do
      Feedzirra::Feed.determine_feed_parser_for_xml(sample_atom_feed).should == Feedzirra::Atom
    end
    
    it "should return the Feedzirra::AtomFeedBurner class for an atom feedburner feed" do
      Feedzirra::Feed.determine_feed_parser_for_xml(sample_feedburner_atom_feed).should == Feedzirra::AtomFeedBurner
    end
    
    it "should return the Feedzirra::RSS class for an rdf/rss 1.0 feed" do
      Feedzirra::Feed.determine_feed_parser_for_xml(sample_rdf_feed).should == Feedzirra::RSS
    end
    
    it "should return the Feedzirra::RSS class for an rss feedburner feed" do
      Feedzirra::Feed.determine_feed_parser_for_xml(sample_rss_feed_burner_feed).should == Feedzirra::RSS
    end
    
    it "should return the Feedzirra::RSS object for an rss 2.0 feed" do
      Feedzirra::Feed.determine_feed_parser_for_xml(sample_rss_feed).should == Feedzirra::RSS
    end
  end
  
  describe "adding feed types" do
    it "should prioritize added feed types over the built in ones" do
      feed_text = "Atom asdf"
      Feedzirra::Atom.should be_able_to_parse(feed_text)
      new_feed_type = Class.new do
        def self.able_to_parse?(val)
          true
        end
      end
      new_feed_type.should be_able_to_parse(feed_text)
      Feedzirra::Feed.add_feed_class(new_feed_type)
      Feedzirra::Feed.determine_feed_parser_for_xml(feed_text).should == new_feed_type
      
      # this is a hack so that this doesn't break the rest of the tests
      Feedzirra::Feed.feed_classes.reject! {|o| o == new_feed_type }
    end
  end
  
  describe "header parsing" do
    before(:each) do
      @header = "HTTP/1.0 200 OK\r\nDate: Thu, 29 Jan 2009 03:55:24 GMT\r\nServer: Apache\r\nX-FB-Host: chi-write6\r\nLast-Modified: Wed, 28 Jan 2009 04:10:32 GMT\r\nETag: ziEyTl4q9GH04BR4jgkImd0GvSE\r\nP3P: CP=\"ALL DSP COR NID CUR OUR NOR\"\r\nConnection: close\r\nContent-Type: text/xml;charset=utf-8\r\n\r\n"
    end
    
    it "should parse out an etag" do
      Feedzirra::Feed.etag_from_header(@header).should == "ziEyTl4q9GH04BR4jgkImd0GvSE"
    end
    
    it "should return nil if there is no etag in header" do
      Feedzirra::Feed.etag_from_header("foo").should be_nil
    end
    
    it "should parse out a last-modified date" do
      Feedzirra::Feed.last_modified_from_header(@header).should == Time.parse("Wed, 28 Jan 2009 04:10:32 GMT")
    end
    
    it "should return nil if there is no last-modified in header" do
      Feedzirra::Feed.last_modified_from_header("foo").should be_nil
    end
  end
  
  describe "fetching feeds" do
    before(:each) do
      @paul_feed_url = "http://feeds.feedburner.com/PaulDixExplainsNothing"
      @trotter_feed_url = "http://feeds.feedburner.com/trottercashion"
    end
        
    describe "handling many feeds" do
      it "should break a large number into more manageable blocks of 40"
      it "should add to the queue as feeds finish (instead of waiting for each block of 40 to finsih)"
    end

    describe "#fetch_raw" do
      it "should take :user_agent as an option"
      it "should take :if_modified_since as an option"
      it "should take :if_none_match as an option"
      it "should take an optional on_success lambda"
      it "should take an optional on_failure lambda"
      
      it "should return raw xml" do
        Feedzirra::Feed.fetch_raw(@paul_feed_url).should =~ /^#{Regexp.escape('<?xml version="1.0" encoding="utf-8"?>')}/i
      end
      
      it "should take multiple feed urls and return a hash of urls and response xml" do
        results = Feedzirra::Feed.fetch_raw([@paul_feed_url, @trotter_feed_url])
        results.keys.should include(@paul_feed_url)
        results.keys.should include(@trotter_feed_url)
        results[@paul_feed_url].should =~ /Paul Dix/
        results[@trotter_feed_url].should =~ /Trotter Cashion/
      end
      
      it "should always return a hash when passed an array" do
        results = Feedzirra::Feed.fetch_raw([@paul_feed_url])
        results.class.should == Hash
      end
    end
    
    describe "#fetch_and_parse" do
      it "should return a feed object for a single url" do
        feed = Feedzirra::Feed.fetch_and_parse(@paul_feed_url)
        feed.title.should == "Paul Dix Explains Nothing"
      end
      
      it "should set the feed_url to the new url if redirected" do
        feed = Feedzirra::Feed.fetch_and_parse("http://tinyurl.com/tenderlovemaking")
        feed.feed_url.should == "http://tenderlovemaking.com/feed/"
      end
      
      it "should set the feed_url for an rdf feed" do
        feed = Feedzirra::Feed.fetch_and_parse("http://www.avibryant.com/rss.xml")
        feed.feed_url.should == "http://www.avibryant.com/rss.xml"
      end
      
      it "should set the feed_url for an rss feed" do
        feed = Feedzirra::Feed.fetch_and_parse("http://tenderlovemaking.com/feed/")
        feed.feed_url.should == "http://tenderlovemaking.com/feed/"
      end
      
      it "should return a hash of feed objects with the passed in feed_url for the key and parsed feed for the value for multiple feeds" do
        feeds = Feedzirra::Feed.fetch_and_parse([@paul_feed_url, @trotter_feed_url])
        feeds.size.should == 2
        feeds[@paul_feed_url].feed_url.should == @paul_feed_url
        feeds[@trotter_feed_url].feed_url.should == @trotter_feed_url
      end
      
      it "should always return a hash when passed an array" do
        feeds = Feedzirra::Feed.fetch_and_parse([@paul_feed_url])
        feeds.class.should == Hash
      end
      
      it "should yeild the url and feed object to a :on_success lambda" do
        successful_call_mock = mock("successful_call_mock")
        successful_call_mock.should_receive(:call)
        Feedzirra::Feed.fetch_and_parse(@paul_feed_url, :on_success => lambda { |feed_url, feed|
          feed_url.should == @paul_feed_url
          feed.class.should == Feedzirra::AtomFeedBurner
          successful_call_mock.call})
      end
      
      it "should yield the url, response_code, response_header, and response_body to a :on_failure lambda" do
        failure_call_mock = mock("failure_call_mock")
        failure_call_mock.should_receive(:call)
        fail_url = "http://localhost"
        Feedzirra::Feed.fetch_and_parse(fail_url, :on_failure => lambda {|feed_url, response_code, response_header, response_body|
          feed_url.should == fail_url
          response_code.should == 0
          response_header.should == ""
          response_body.should == ""
          failure_call_mock.call})
      end
      
      it "should return a not modified status for a feed with a :if_modified_since is past its last update" do
        Feedzirra::Feed.fetch_and_parse(@paul_feed_url, :if_modified_since => Time.now).should == 304
      end
      
      it "should set the etag from the header" # do
       #        Feedzirra::Feed.fetch_and_parse(@paul_feed_url).etag.should_not == ""
       #      end
      
      it "should set the last_modified from the header" # do
       #        Feedzirra::Feed.fetch_and_parse(@paul_feed_url).last_modified.should.class == Time
       #      end
    end

    describe "#update" do
      it "should update and return a single feed object" do
        feed = Feedzirra::Feed.fetch_and_parse(@paul_feed_url)
        feed.entries.delete_at(0)
        feed.last_modified = nil
        feed.etag = nil
        updated_feed = Feedzirra::Feed.update(feed)
        updated_feed.new_entries.size.should == 1
        updated_feed.should have_new_entries
      end

      it "should update a collection of feed objects" do
        feeds = Feedzirra::Feed.fetch_and_parse([@paul_feed_url, @trotter_feed_url])
        paul_entries_size    = feeds[@paul_feed_url].entries.size
        trotter_entries_size = feeds[@trotter_feed_url].entries.size
        
        feeds.values.each do |feed|
          feed.last_modified = nil
          feed.etag = nil
          feed.entries.delete_at(0)
        end
        updated_feeds = Feedzirra::Feed.update(feeds.values)
        updated_feeds.detect {|f| f.feed_url == @paul_feed_url}.entries.size.should == paul_entries_size
        updated_feeds.detect {|f| f.feed_url == @trotter_feed_url}.entries.size.should == trotter_entries_size
      end
      
      it "should return the feed objects even when not updated" do
        feeds = Feedzirra::Feed.fetch_and_parse([@paul_feed_url, @trotter_feed_url])
        updated_feeds = Feedzirra::Feed.update(feeds.values)
        updated_feeds.size.should == 2
        updated_feeds.first.should_not be_updated
        updated_feeds.last.should_not be_updated
      end
    end
  end
end