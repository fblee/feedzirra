require File.dirname(__FILE__) + '/../spec_helper'

describe Feedzirra::FeedUtilities do
  before(:each) do
    @klass = Class.new do
      include Feedzirra::FeedEntryUtilities
    end
  end
  
  describe "handling dates" do
    it "should parse an ISO 8601 formatted datetime into Time" do
      time = @klass.new.parse_datetime("2008-02-20T8:05:00-010:00")
      time.class.should == Time
      time.to_s.should == "Wed Feb 20 18:05:00 UTC 2008"
    end
      
    it "should parse a bunch of strangely encoded stuff into Time" do
      # note this test needs updating every month to correct the month name
      time = @klass.new.parse_datetime("Mon, 4 Jan 7010 13:51:39 EST")
      time.class.should == Time
      time.to_s.should == "Mon Jan 04 18:51:39 UTC 2010"
        
      time = @klass.new.parse_datetime("’ªÓ, 5 1“ÝÓ 2010 10:37 -0500")
      time.class.should == Time
      time.to_s.should == "Tue Jan 05 15:37:00 UTC 2010"
    end
      
    it "should parse dates used by fox news" do
      time = @klass.new.parse_datetime("Thu, 13 May       2010 13:58:28 EST")
      time.class.should == Time
      time.to_s.should == "Thu May 13 18:58:28 UTC 2010"
    end
  end
  
  describe "sanitizing" do
    before(:each) do
      @feed = Feedzirra::Feed.parse(sample_atom_feed)
      @entry = @feed.entries.first
    end
    
    it "should provide a sanitized title" do
      new_title = "<script>" + @entry.title
      @entry.title = new_title
      @entry.title.sanitize.should == Dryopteris.sanitize(new_title)
    end
    
    it "should sanitize content in place" do
      new_content = "<script>" + @entry.content
      @entry.content = new_content.dup
      @entry.content.sanitize!.should == Dryopteris.sanitize(new_content)
      @entry.content.should == Dryopteris.sanitize(new_content)
    end
    
    it "should sanitize things in place" do
      @entry.title   += "<script>"
      @entry.author  += "<script>"
      @entry.content += "<script>"

      cleaned_title   = Dryopteris.sanitize(@entry.title)
      cleaned_author  = Dryopteris.sanitize(@entry.author)
      cleaned_content = Dryopteris.sanitize(@entry.content)
      
      @entry.sanitize!
      @entry.title.should   == cleaned_title
      @entry.author.should  == cleaned_author
      @entry.content.should == cleaned_content
    end
  end
end