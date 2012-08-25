module Suby
  # Based on https://github.com/byroot/ruby-osdb/blob/master/lib/osdb/server.rb
  class Downloader::OpenSubtitles < Downloader
    SITE = 'api.opensubtitles.org'
    FORMAT = :zip
    XMLRPC_PATH = '/xml-rpc'

    USERNAME = ''
    PASSWORD = ''
    LOGIN_LANGUAGE = 'eng'
    USER_AGENT = 'OS Test User Agent'

    SEARCH_QUERIES_ORDER = [:hash, :name] #There is also search using imdbid but i dont think it usefull as it
                                          #returns subtitles for many different versions

    # OpenSubtitles needs ISO 639-2 language codes for subtitles search
    # http://en.wikipedia.org/wiki/List_of_ISO_639-2_codes
    LANG_MAPPING = {
      en: 'eng', es: 'spa', it: 'ita', fr: 'fra', pt: 'por', de: 'deu', ca: 'cat', eu: 'eus', cs: 'ces', gl: 'glg',
      tr: 'tur', nl: 'nld', sv: 'swe', ru: 'rus', hu: 'hun', pl: 'pol', sl: 'slv', he: 'heb', zh: 'zho', sk: 'slk',
      ro: 'ron', el: 'ell', fi: 'fin', da: 'dan', hr: 'hrv', ja: 'jpn', bg: 'bul', sr: 'srp', id: 'ind', ar: 'ara',
      ms: 'msa', ko: 'kor', fa: 'fas', bs: 'bos', vi: 'vie', th: 'tha', bn: 'ben', no: 'nor'
    }
    LANG_MAPPING.default = 'all'
    SUBTITLE_TYPES = [:tvshow, :movie, :unknown]

    def subtitles_url
      for type in SEARCH_QUERIES_ORDER
        subs = search_subtitles(search_query(type))['data']
        break if subs
      end
      raise NotFoundError, "no subtitle available" unless subs
      subs.first['ZipDownloadLink']
    end

    def search_subtitles(query)
      return {} if query.nil?
      query = [query] unless query.kind_of? Array
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

    def search_query(type = :hash)
      query = send("search_query_by_#{type}")
      query.merge(sublanguageid: language(lang)) unless query.empty?
    end

    def search_query_by_hash
      @file.exist? ? { moviehash: MovieHasher.compute_hash(file), moviebytesize: file.size.to_s } : {}
    end

    def search_query_by_name
      season && episode ? { query: show, season: season, episode: episode } : { query: file.basename.to_s }
    end

    def search_query_by_imdbid
      { imdbid: imdbid } if imdbid
    end

    def language(lang)
      LANG_MAPPING[lang.to_sym]
    end

    def download_url
      @download_url ||= subtitles_url
    end
  end
end
