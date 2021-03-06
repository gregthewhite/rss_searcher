require_relative "rss_reader.rb"
require 'date'

INTEREST_LEVEL_ALL = "ALL"
INTEREST_LEVEL_ONE_OR_MORE = "ONE_OR_MORE"

class RSS_Keyword_Searcher 

  def initialize(feed_urls, keywords, match_level, minimum_publish_date=Date.today)
    @reader = RSS_Reader.new(feed_urls)
    @news_items = @reader.get_news_items
    @keywords = keywords
    @match_level = match_level
    @minimum_publish_date = minimum_publish_date
    raise ArgumentError, "no valid feed urls given" unless @news_items
    raise ArgumentError, "no keywords given" unless keywords.is_a?(Array) && keywords.length > 0
    raise ArgumentError, "invalid match_level" unless self.valid_match_level(match_level)
  end

  def get_links_of_interest(links_of_interest=Array.new)
    @news_items.each do |item|
      content = self.content_from_item(item)
      next if self.out_of_date(item)
      links_of_interest.push(item.link) if self.is_of_interest(content)
    end
    return links_of_interest
  end

  def is_of_interest(content)
    if(@match_level === INTEREST_LEVEL_ALL)
      regex_string = @keywords.inject("") {|ret, keyword| ret+"(?=.*#{keyword.downcase})"}
      return content =~ /#{regex_string}/
    elsif(@match_level === INTEREST_LEVEL_ONE_OR_MORE)
      regex_string = @keywords.map(&:downcase).join("|")
      return content =~ /#{regex_string}/
    elsif(@match_level.is_a?(Integer) && @match_level > 1 && @match_level < 100 )
      match_percentage = self.get_keyword_match_percentage(content)
      (match_percentage*100) > @match_level ? (return true) : (return false)
    else
      return false
    end
  end

  def event_triggered?(flag=false)
    @news_items.each do |item|
      content = self.content_from_item(item)
      flag = self.is_of_interest(content)
      return flag if flag
    end
    return flag
  end

  def get_keyword_match_percentage(content)
    match_count = 0
    @keywords.each do |keyword|
      if content.include?(keyword.downcase)
        match_count += 1 
      end
    end
    return (match_count * 1.0) / @keywords.length
  end

  def out_of_date(news_item)
    pub_date_string = news_item.pubDate.to_s
    pub_date = Date.parse(pub_date_string)
    return pub_date < @minimum_publish_date
  end

  def content_from_item(item)
    content_string = item.categories.each_with_object("") do |category, string|
      string.concat category.content
    end
    return (content_string+item.description+item.title).downcase
  end

  def valid_match_level(match_level)
    return (match_level === INTEREST_LEVEL_ALL || match_level === INTEREST_LEVEL_ONE_OR_MORE || (match_level.is_a?(Integer) && match_level > 1 && match_level < 100))
  end

end