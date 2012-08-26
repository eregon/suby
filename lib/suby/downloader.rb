require 'net/http'
require 'cgi/util'
require 'nokogiri'
require 'xmlrpc/client'

module Suby
  class Downloader
    DOWNLOADERS = []
    def self.inherited(downloader)
      DOWNLOADERS << downloader
    end

    attr_reader :show, :season, :episode, :video_data, :file, :lang

    def initialize(file, *args)
      @file = file
      @lang = (args.last || 'en').to_sym
      @video_data = FilenameParser.parse(file)
      if video_data[:type] == :tvshow
        @show, @season, @episode = video_data.values_at(:show, :season, :episode)
      end
    end

    def support_video_type?
      self.class::SUBTITLE_TYPES.include? video_data[:type]
    end

    def to_s
      self.class.name.sub(/^.+::/, '')
    end

    def http
      @http ||= Net::HTTP.new(self.class::SITE).start
    end

    def xmlrpc
      @xmlrpc ||= XMLRPC::Client.new(self.class::SITE, self.class::XMLRPC_PATH)
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
        sub_name(contents).write contents
      when :zip
        TEMP_ARCHIVE.write contents
        Suby.extract_sub_from_archive(TEMP_ARCHIVE, format, file)
      else
        raise "unknown subtitles format: #{format}"
      end
    end

    def sub_name(contents)
      file.sub_ext sub_extension(contents)
    end

    def sub_extension(contents)
      if contents[0..10] =~ /1\r?\n/
        'srt'
      else
        'sub'
      end
    end

    def imdbid
      @imdbid ||= begin
        nfo_file = find_nfo_file
        convert_to_utf8(nfo_file.read)[%r!imdb\.[^/]+/title/tt(\d+)!i, 1] if nfo_file
      end
    end

    def find_nfo_file
      @file.dir.children.find { |file| file.ext == "nfo" }
    end

    def convert_to_utf8(content)
      if content.valid_encoding?
        content
      else
        content.encode("UTF-8", "ISO-8859-1")
      end
    end

    def success_message
      "Found"
    end
  end
end

# Defines downloader order
%w[
    tvsubtitles
    addic7ed
    opensubtitles
  ].each { |downloader| require_relative "downloader/#{downloader}" }
