require 'net/http'
require 'nokogiri'

module Suby
  class Downloader
    attr_reader :show, :season, :episode, :file, :lang

    def initialize file, lang = nil
      @file, @lang = file, lang || 'en'
      unless /^(?<show>.+) (?<season>\d{1,2})x(?<episode>\d{1,2})(?: - .+)?\.[a-z]+?$/ =~ file
        raise "wrong file format (#{file}). Must be:\n<show> <season>x<episode>[ - <title>].<ext>"
      end
      @show, @season, @episode = show, season.to_i, episode.to_i
    end

    def http
      @http ||= Net::HTTP.new(self.class::SITE).start
    end

    def download
      puts "Searching subtitles for #{file}:"
      puts "Show: #{show}, Season: #{season}, Episode: #{episode}"

      puts "show url: #{show_url}"
      puts "episode url: #{episode_url}"
      puts "subtitle url: #{subtitles_url}"
      puts "download url: #{download_url}"

      # extract
      zip = http.get(download_url).body
      http.finish
      open(TEMP_ARCHIVE_NAME, 'wb') { |f| f.write zip }
      subs = Suby.extract_subs_from_archive(TEMP_ARCHIVE_NAME)

      new_name = File.basename(file, File.extname(file))+File.extname(subs.first)
      File.rename subs.first, new_name
      puts "Renaming to #{new_name}"
    end
  end
end

require_relative 'downloader/tvsubtitles'
