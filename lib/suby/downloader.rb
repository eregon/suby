require 'net/http'
require 'cgi/util'
require 'nokogiri'

module Suby
  class Downloader
    DOWNLOADERS = []
    def self.add(downloader)
      DOWNLOADERS << downloader
    end

    attr_reader :show, :season, :episode, :file, :lang

    def initialize(file, *args)
      @file = file
      @lang = (args.last || 'en').to_sym
      case args.size
      when 0..1
        @show, @season, @episode = FilenameParser.parse(file)
      when 3..4
        @show, @season, @episode = args
      else
        raise ArgumentError, "wrong number of arguments: #{args.size+1} for " +
                             "(file, [show, season, episode], [lang])"
      end
    end

    def to_s
      self.class.name.sub(/^.+::/, '')
    end

    def http
      @http ||= Net::HTTP.new(self.class::SITE).start
    end

    def get(path, initheader = {}, parse_response = true)
      response = http.get(path, initheader)
      if parse_response
        unless Net::HTTPSuccess === response
          raise DownloaderError, "Invalid response for #{path}: #{response}"
        end
        response.body
      else
        response
      end
    end

    def post(path, data = {}, initheader = {})
      post = Net::HTTP::Post.new(path, initheader)
      post.form_data = data
      response = http.request(post)
      unless Net::HTTPSuccess === response
        raise DownloaderError, "Invalid response for #{path}(#{data}): " +
                               response.inspect
      end
      response.body
    end

    def get_redirection(path, initheader = {})
      response = http.get(path, initheader)
      location = response['Location']
      unless (Net::HTTPFound === response or
              Net::HTTPSuccess === response) and location
        raise DownloaderError, "Invalid response for #{path}: " +
              "#{response}: location: #{location.inspect}, #{response.body}"
      end
      location
    end

    def download
      extract download_url
    end

    def subtitles(url_or_response = download_url)
      if Net::HTTPSuccess === url_or_response
        url_or_response.body
      else
        get(url_or_response)
      end
    end

    def extract(url_or_response)
      contents = subtitles(url_or_response)
      http.finish
      format = self.class::FORMAT
      case format
      when :file
        open(sub_name(contents), 'wb') { |f| f.write contents }
      when :zip
        open(TEMP_ARCHIVE_NAME, 'wb') { |f| f.write contents }
        Suby.extract_sub_from_archive(TEMP_ARCHIVE_NAME, format, basename)
      else
        raise "unknown subtitles format: #{format}"
      end
    end

    def basename
      File.basename(file, File.extname(file))
    end

    def sub_name(contents)
      basename + sub_extension(contents)
    end

    def sub_extension(contents)
      if contents[0..10] =~ /1\r?\n/
        '.srt'
      else
        '.sub'
      end
    end
  end
end

require_relative 'downloader/tvsubtitles'
require_relative 'downloader/addic7ed'
