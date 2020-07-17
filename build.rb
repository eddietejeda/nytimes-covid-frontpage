#!/usr/bin/env ruby
require 'date'    
require 'pdf-reader'
require 'open-uri'
require 'json'


def nytimes_url(date)
  "https://static01.nyt.com/images/#{date.strftime('%Y/%m/%d')}/nytfrontpage/scan.pdf"
end

def download_nytimes_frontpage(start_date, end_date)
  ( start_date .. end_date ).each do |current_time|
    puts "checking #{nytimes_url(current_time)}"
    filename = File.join("pdfs", "#{current_time.to_s}.pdf")
  # unless File.file? filename
    puts "saving... #{current_time.to_s}.pdf"
    begin
      File.open(filename, "wb") do |file|
        file.write open(nytimes_url(current_time)).read
      end
    rescue => error
      puts "Failed to download #{nytimes_url(current_time)} / #{error}"
    end
  # end
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
      puts "Failed to read #{filename} / #{error}"
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

def json_incremented?(new_data, current_filename)
  begin
    contents = File.read(File.join("data",current_filename))
  rescue => error
    contents = "{}"
  end
  old_data = JSON.parse( contents )  
  puts "new count: #{new_data.count} old count: #{old_data.count}"
  new_data.count > old_data.count
end


start_date = DateTime.parse('2019-12-01').to_date # A month before the first covid case
end_date = Date.today - 1

download_nytimes_frontpage(start_date, end_date)
new_data = generate_word_count_from_pdf

if json_incremented?(new_data, "results.json")
  puts "saving new file"
  save_json(new_data, "results.json")
else
  puts "new file not saved"
end