#!/usr/bin/env ruby
require 'date'    
require 'pdf-reader'
require 'open-uri'
require 'json'

def download_nytimes_frontpage(start_date, end_date, path)
  ( start_date .. end_date ).each do |current|
    filename = "#{path}/#{current.to_s}.pdf"
    unless File.file? filename
      puts "dowloading... #{current.to_s}"
      File.open(filename, "wb") do |file|
        file.write open("https://static01.nyt.com/images/#{current.strftime('%Y/%m/%d')}/nytfrontpage/scan.pdf").read
      end
    end
  end
end

def count_words_in_pdf(path, words)
  results = {}
  Dir["#{path}/*.pdf"].each do |filename|
    reader = PDF::Reader.new(filename)
    reader.pages.each do |page|
      current_time = Date.parse(File.basename(filename, File.extname(filename))).to_time.to_i      
      results.merge!("#{current_time}": page.text.downcase.scan(/(?=(corona|covid))/).count)
    end
  end
  results
end

def save_json(results, filename)
  File.open(filename,"w") do |f|
    f.write(JSON.generate(results))
  end
end


end_date = Date.today
start_date = end_date - 3
# start_date = today - Date.today.yday() + 1

download_nytimes_frontpage(start_date, end_date, "./download")
results = count_words_in_pdf("./download", [])
save_json(results, "results.json")


