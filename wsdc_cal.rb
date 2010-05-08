#!/usr/bin/ruby
require 'rubygems'
require 'open-uri'
require 'hpricot'
require 'ri_cal'

def verbose(string)
  puts string
end

cal = RiCal.Calendar do |cal|

  cal.add_x_property("X-WR-CALNAME", "WSDC Events")
  cal.add_x_property("X-WR-CALDESC", "World Swing Dance Council Event Calendar")

  doc = Hpricot(open("http://www.swingdancecouncil.com/ActiveServerPages/UpcomingEvents.asp"))
  trs = doc.search('//tr/td/a../..')
  trs.each do |tr| 
    text = tr.search('//td').inner_html.split("\n")
    verbose("text => #{text}")
    
    date = text.at(1)
    verbose("date => '#{date}'")
    
    d = date.scan(/\w+/)
    if d.empty?
      verbose("(skipping)")
      next
    end
    
    if (d.length == 5)  # Prob a date of form 'Apr 30 - May 8, 2010'

      # Try to detect when year should be different
      y_adj = 0
      if d[0] =~ /Dec/ and d[2] =~ /Jan/
        verbose("(adjusting year)")
        y_adj = 1
      end
        
      verbose("d = [ '#{d[0]}', '#{d[1]}', '#{d[2]}', '#{d[3]}', '#{d[4]}', '#{d[5]}'")

      dbeg = Date.parse("#{d[0]} #{d[1]} #{d[4]}")
      verbose("dbeg => #{dbeg}")
      dend = Date.parse("#{d[2]} #{d[3]} #{d[4].to_i + y_adj}")
      verbose("dend => #{dend}")

    elsif d.length == 4  # Date of form 'Apr 7 - 9, 2010'

      verbose("d = [ '#{d[0]}', '#{d[1]}', '#{d[2]}', '#{d[3]}', '#{d[4]}'")

      dbeg = Date.parse("#{d[0]} #{d[1]} #{d[3]}")
      verbose("dbeg => #{dbeg}")
      dend = Date.parse("#{d[0]} #{d[2]} #{d[3]}")
      verbose("dend => #{dend}")

    else
      verbose("(skipping)")
      next
    end
    
    desc = text.at(4).scan(/>(.*)</)
    if desc.empty?
      verbose("(skipping)")
      next
    end
    verbose("desc => '#{desc}'")
    
    url = text.at(4).scan(/href=\"(.*)\">/)
    verbose("url => '#{url}'")
    
    loc = text.at(7)
    verbose("loc => '#{loc}'")

    cal.event do |event|
      event.summary     = desc.at(0).at(0)
      event.dtstart     = dbeg
      event.dtend       = dend + 1  # WTF
      event.location    = loc
      event.url         = url.at(0).at(0)
    end
  end
end

puts cal
