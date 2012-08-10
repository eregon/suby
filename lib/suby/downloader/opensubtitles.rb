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

    # OpenSubtitles needs ISO 639-2 language codes for subtitles search
    # http://en.wikipedia.org/wiki/List_of_ISO_639-2_codes
    LANG_MAPPING = {
      en: 'eng', es: 'spa', it: 'ita', fr: 'fra', pt: 'por', de: 'deu', ca: 'cat', eu: 'eus', cs: 'ces', gl: 'glg',
      tr: 'tur', nl: 'nld', sv: 'swe', ru: 'rus', hu: 'hun', pl: 'pol', sl: 'slv', he: 'heb', zh: 'zho', sk: 'slk',
      ro: 'ron', el: 'ell', fi: 'fin', da: 'dan', hr: 'hrv', ja: 'jpn', bg: 'bul', sr: 'srp', id: 'ind', ar: 'ara',
      ms: 'msa', ko: 'kor', fa: 'fas', bs: 'bos', vi: 'vie', th: 'tha', bn: 'ben', no: 'nor'
    }
    LANG_MAPPING.default = 'all'

    def subtitles_url(query = subtitles_search_query)
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
        raise DownloaderError "Failed to login with #{USERNAME} : #{PASSWORD}. " +
                              "Server return code: #{response['status']}"
      end
      response['token']
    end

    def subtitles_search_query
      [{'moviehash' => MovieHasher.compute_hash(@file.path), 'moviebytesize' => @file.size.to_s,
        'sublanguageid' => language(lang)}]
    end

    def language(lang)
      LANG_MAPPING[lang.to_sym]
    end

    def download_url
      @client ||= ::XMLRPC::Client.new(SITE, XMLRPC_PATH)
      @download_url ||= subtitles_url
    end
  end
end
