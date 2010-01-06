module Feedzirra
  module FeedEntryUtilities    
    def published
      @published || @updated
    end
    
    def parse_datetime(string)
      begin
        return DateTime.parse(string).feed_utils_to_gm_time
      rescue
        # This means the date was not in an expected format. Often publishers use bizarre character encodings
        # and/or foreign languages in day or month names, so we try and ignore bogus data and see if it's possible
        # to make a sensible extraction of the data that is parseable.
          
        # This reg exp matches string like: ?¤„â, 1 ???¼„â 2009 14:26 -0400
        # which we take to mean the 1st of the current month, at 14:26 in Eastern Summer Time.
        date_matcher = /.+?\s+(\d?\d)\s+.+?(\d\d\d\d)\s+(\d?\d):(\d\d):?(\d?\d)?\s+([-+]\d\d\d\d|\w\w\w)/
        processed_date = date_matcher.match(string)
        if processed_date.nil?
            puts "DATE CAN'T BE PARSED: #{string}"
            return nil
        else
            day_number = processed_date[1].to_i
            year = processed_date[2].to_i
            # sanitize future years to be this year
            today = DateTime.now
            current_year = today.year
            year = current_year if year > current_year

            # Guess the month: if the day number is less than today 
            if day_number > today.day
                month = (today << 1).month
            else
                month = today.month
            end

            hours = processed_date[3].to_i
            minutes = processed_date[4].to_i
            seconds = processed_date[5] || "00"
            timezone_indicator = processed_date[6]

            parsed_datetime_string = "#{year}-#{month}-#{day_number} #{hours}:#{minutes}:#{seconds} #{timezone_indicator}"
#            puts parsed_datetime_string
            correct_date = DateTime.parse(parsed_datetime_string)
            gmt_date = correct_date.feed_utils_to_gm_time
            puts "Correctly sanitized a date string after initial parse failed. Went from: [#{string}] to [#{gmt_date.to_s}] via [#{correct_date.to_s}]"
            return gmt_date
        end
      end
    end
    
    ##
    # Returns the id of the entry or its url if not id is present, as some formats don't support it
    def id
      @id || @url
    end
    
    ##
    # Writter for published. By default, we keep the "oldest" publish time found.
    def published=(val)
      parsed = parse_datetime(val)
      @published = parsed if !@published || parsed < @published
    end
    
    ##
    # Writter for udapted. By default, we keep the most recenet update time found.
    def updated=(val)
      parsed = parse_datetime(val)
      @updated = parsed if !@updated || parsed > @updated
    end

    def sanitize!
      self.title.sanitize!   if self.title
      self.author.sanitize!  if self.author
      self.summary.sanitize! if self.summary
      self.content.sanitize! if self.content
    end
    
    alias_method :last_modified, :published
  end
end
