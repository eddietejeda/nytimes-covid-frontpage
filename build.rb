#!/usr/bin/env ruby
require 'date'
require 'pdf-reader'
require 'open-uri'
require 'json'
require 'net/http'
require 'active_support'
require 'active_support/core_ext/date/calculations'


def data_file(filename)
  if(ENV['APP_ENV'] == "production")
    "https://nytimes-covid-frontpage.s3.amazonaws.com/#{filename}"
  else
    File.join("data",filename)
  end
end

def nytimes_url(date)
  "https://static01.nyt.com/images/#{date.strftime('%Y/%m/%d')}/nytfrontpage/scan.pdf"
end

def download_nytimes_frontpage(start_date, end_date)
  ( start_date .. end_date ).each do |current_time|
    puts "🌎 Checking URL #{nytimes_url(current_time)}"
    filename = File.join("pdfs", "#{current_time.to_s}.pdf")
    if !File.file?(filename) || File.zero?(filename)
      begin
        puts "📗 Download new file: #{current_time.to_s}.pdf"
        File.open(filename, "wb") do |file|
          file.write open(nytimes_url(current_time)).read
        end
      rescue => error
        puts "❌  Failed to save #{nytimes_url(current_time)} / #{error}"
      end
    else
      puts "🗄️  Using cached file: #{current_time.to_s}.pdf"
    end
  end
end

def generate_word_count_from_pdf
  puts "🧮 Generating word count..."
  results = {}
  Dir[File.join("pdfs", "*.pdf")].each do |filename|
    begin
      puts "🔍  Analyzing... #{filename}"
      reader = PDF::Reader.new(filename)
      reader.pages.each do |page|
        # Advancing 1 day works around a cal-heatmap off-by-one date bug
        current_time = Date.parse(File.basename(filename, File.extname(filename))).advance(days: 1).to_time.to_i
        results.merge!("#{current_time}": page.text.downcase.scan(/(?=(corona|covid|virus|pandemic|wuhan))/).count)
      end
    rescue => error
      puts "❌ Failed to read #{filename} / #{error}"
    end
  end
  puts "⌛ Processed #{results.count} items"
  results
end

def save_json(data, filename)
  File.open(File.join("data",filename),"w") do |f|
    f.write(JSON.generate(data))
  end
end

def json_incremented?(new_data, old_data_filename)
  begin
    if File.file?(old_data_filename)
      response = File.open(old_data_filenamename).read
    elsif old_data_filename =~ URI::regexp
      uri = URI(data_file(old_data_filename))
      response = Net::HTTP.get(uri)
    else
      response = "{}"
    end
    old_data = JSON.parse(response)
  rescue => error
    puts "❌ Error downloading / #{error}"
  end
  
  puts "New count: #{new_data.count} Old count: #{old_data.count}"
  new_data.count > old_data.count
  
end

def main(start_date:, end_date:)
  puts "APP_ENV=#{ENV['APP_ENV'] || 'development'}"
  download_nytimes_frontpage(start_date, end_date)
  new_data = generate_word_count_from_pdf

  if json_incremented?(new_data, "results.json")
    puts "Writing new JSON file"
    save_json(new_data, "results.json")
  else
    puts "No need to generate a new JSON"
  end
end

main(start_date: DateTime.parse('2020-01-01').to_date, end_date: Date.today)
