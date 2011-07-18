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
      rename extract download_url
    end

    def extract url
      zip = http.get(url).body
      http.finish
      open(TEMP_ARCHIVE_NAME, 'wb') { |f| f.write zip }
      Suby.extract_subs_from_archive(TEMP_ARCHIVE_NAME)
    end

    def rename subs
      new_name = File.basename(file, File.extname(file))+File.extname(subs.first)
      File.rename subs.first, new_name
    end
  end
end

require_relative 'downloader/tvsubtitles'
