module Suby
  # Based on https://github.com/byroot/ruby-osdb/blob/master/lib/osdb/server.rb
  class Downloader::OpenSubtitles < Downloader
    SITE = 'api.opensubtitles.org'
    FORMAT = :zip
    XMLRPC_PATH = '/xml-rpc'

    USERNAME = ''
    PASSWORD = ''
    LOGIN_LANGUAGE = 'eng'
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
      subs = search_subtitles(query)['data']
      raise NotFoundError, "no subtitle available" unless subs
      subs.first['ZipDownloadLink']
    end

    def search_subtitles(query)
      xmlrpc.call('SearchSubtitles', token, query)
    end

    def token
      @token ||= login
    end

    def login
      response = xmlrpc.call('LogIn', USERNAME, PASSWORD, LOGIN_LANGUAGE, USER_AGENT)
      unless response['status'] == '200 OK'
        raise DownloaderError "Failed to login with #{USERNAME} : #{PASSWORD}. " +
                              "Server return code: #{response['status']}"
      end
      response['token']
    end

    def subtitles_search_query
      raise NotFoundError, "cant search subtitles for non existing file" unless @file.exist?
      [{:moviehash => MovieHasher.compute_hash(@file.path), :moviebytesize => @file.size.to_s,
        :sublanguageid => language(lang)}]
    end

    def language(lang)
      LANG_MAPPING[lang.to_sym]
    end

    def download_url
      @download_url ||= subtitles_url
    end
  end
end
