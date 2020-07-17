#!/usr/bin/env ruby
require 'date'    
require 'pdf-reader'
require 'open-uri'
require 'json'



def download_nytimes_frontpage(start_date, end_date)
  ( start_date .. end_date ).each do |current|
    filename = File.join("pdfs", "#{current.to_s}.pdf")
    unless File.file? filename
      puts "downloading... #{current.to_s}"
      begin
        File.open(filename, "wb") do |file|
          file.write open("https://static01.nyt.com/images/#{current.strftime('%Y/%m/%d')}/nytfrontpage/scan.pdf").read
        end
      rescue OpenURI::HTTPError => ex
        puts "Failed to download #{current.strftime('%Y/%m/%d')}"
      end
    end
  end
end

def generate_word_count_from_pdf
  puts "generating word count..."
  results = {}
  Dir[File.join("pdfs", "*.pdf")].each do |filename|
    reader = PDF::Reader.new(filename)
    reader.pages.each do |page|
      current_time = Date.parse(File.basename(filename, File.extname(filename))).to_time.to_i      
      results.merge!("#{current_time}": page.text.downcase.scan(/(?=(corona|covid|virus|pandemic|wuhan))/).count)
    end
  end
  puts "processed #{results.count} items"
  results
end

def save_json(data, filename)
  File.open(File.join("data",filename),"w") do |f|
    f.write(JSON.generate(data))
  end
end


start_date = DateTime.parse('2019-12-01').to_date # A month before the first covid case
end_date = Date.today

download_nytimes_frontpage(start_date, end_date)
save_json(generate_word_count_from_pdf, "results.json")