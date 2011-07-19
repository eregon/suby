require 'net/http'
require 'cgi/util'
require 'nokogiri'

module Suby
  class Downloader
    attr_reader :show, :season, :episode, :title, :file, :lang

    def initialize file, lang = nil
      @file, @lang = file, (lang || 'en').to_sym
      unless /^(?<show>.+) (?<season>\d{1,2})x(?<episode>\d{1,2})(?: - (?<title>.+))?\.[a-z]+?$/ =~ file
        raise "wrong file format (#{file}). Must be:\n<show> <season>x<episode>[ - <title>].<ext>"
      end
      @show, @season, @episode, @title = show, season.to_i, episode.to_i, title
    end

    def http
      @http ||= Net::HTTP.new(self.class::SITE).start
    end

    def download
      extract download_url
    end

    def extract url
      contents = http.get(url).body
      http.finish
      format = self.class::FORMAT
      if format == :file
        open(sub_name(url), 'wb') { |f| f.write contents }
      else
        open(TEMP_ARCHIVE_NAME, 'wb') { |f| f.write contents }
        sub = Suby.extract_sub_from_archive(TEMP_ARCHIVE_NAME, format)
        File.rename sub, sub_name(sub)
      end
    end

    def sub_name sub
      File.basename(file, File.extname(file)) + File.extname(sub)
    end
  end
end

require_relative 'downloader/tvsubtitles'
