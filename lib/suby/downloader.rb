require 'net/http'
require 'cgi/util'
require 'nokogiri'
require_relative 'filename_parser'

module Suby
  class Downloader
    DOWNLOADERS = []
    def self.inherited subclass
      DOWNLOADERS << subclass
    end

    attr_reader :show, :season, :episode, :title, :file, :lang

    def initialize file, lang = nil
      @file, @lang = file, (lang || 'en').to_sym
      @show, @season, @episode, @title = FilenameParser.parse(file)
    end

    def http
      @http ||= Net::HTTP.new(self.class::SITE).start
    end

    def get path, initheader = {}
      response = http.get(path, initheader)
      raise "Invalid response for #{path}: #{response}" unless Net::HTTPSuccess === response
      response.body
    end

    def get_redirection path, initheader = {}
      response = http.get(path, initheader)
      location = response['Location']
      unless (Net::HTTPFound === response or Net::HTTPSuccess === response) and location
        raise "Invalid response for #{path}: #{response}"
      end
      location
    end

    def download
      extract download_url
    end

    def extract url
      contents = get(url)
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
require_relative 'downloader/addic7ed'
