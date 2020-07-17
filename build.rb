#!/usr/bin/env ruby
require 'date'    
require 'pdf-reader'
require 'open-uri'
require 'json'


def nytimes_url(d)
  "https://static01.nyt.com/images/#{d.strftime('%Y/%m/%d')}/nytfrontpage/scan.pdf"
end

def download_nytimes_frontpage(start_date, end_date)
  ( start_date .. end_date ).each do |current_time|
    puts "checking #{nytimes_url(current_time)}"
    filename = File.join("pdfs", "#{current_time.to_s}.pdf")
    unless File.file? filename
      puts "downloading... #{current_time.to_s}.pdf"
      begin
        File.open(filename, "wb") do |file|
          file.write open().read
        end
      rescue => error
        puts "Failed to download #{nytimes_url(current_time)} #{error}"
      end
    end
  end
end

def generate_word_count_from_pdf
  puts "generating word count..."
  results = {}
  Dir[File.join("pdfs", "*.pdf")].each do |filename|
    begin
      puts "processing... #{filename}"

      reader = PDF::Reader.new(filename)
      reader.pages.each do |page|
        current_time = Date.parse(File.basename(filename, File.extname(filename))).to_time.to_i      
        results.merge!("#{current_time}": page.text.downcase.scan(/(?=(corona|covid|virus|pandemic|wuhan))/).count)
      end
    rescue => error
      puts "Failed to read #{filename} #{error}"
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
end_date = Date.today - 1

download_nytimes_frontpage(start_date, end_date)
save_json(generate_word_count_from_pdf, "results.json")