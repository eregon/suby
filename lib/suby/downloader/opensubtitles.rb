module Suby
  # Based on https://github.com/byroot/ruby-osdb/blob/master/lib/osdb/server.rb
  class Downloader::OpenSubtitles < Downloader
    SITE = 'api.opensubtitles.org'
    FORMAT = :zip
    XMLRPC_PATH = '/xml-rpc'

    USERNAME = ''
    PASSWORD = ''
    LANGUAGE = 'eng'
    USER_AGENT = 'SubDownloader 2.0.10'

    def subtitles_url
      subs = @client.call('SearchSubtitles', token, query)['data']
      raise NotFoundError, "no subtitle available" unless subs
      subs.first['ZipDownloadLink']
    end

    def token
      @token ||= login
    end

    def login
      response = @client.call('LogIn', USERNAME, PASSWORD, LANGUAGE, USER_AGENT)
      unless response['status'] == '200 OK'
        raise DownloaderError "Failed to login with #{USERNAME} : #{PASSWORD}. Server return code: #{response['status']}"
      end
      response['token']
    end

    def query
      [{'moviehash' => MovieHasher.compute_hash(@file.path), 'moviebytesize' => @file.size, 'sublanguageid' => 'eng'}]
    end

    def download_url
      @client ||= ::XMLRPC::Client.new(SITE, XMLRPC_PATH)
      @download_url ||= subtitles_url
    end
  end
end
