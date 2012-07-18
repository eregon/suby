require 'path'
require 'zip/zip'

Path.require_tree 'suby', except: %w[downloader/]

module Suby
  NotFoundError = Class.new StandardError
  DownloaderError = Class.new StandardError

  SUB_EXTENSIONS = %w[srt sub]
  TEMP_ARCHIVE = Path('__archive__')

  class << self
    include Interface

    def download_subtitles(files, options = {})
      files.each { |file|
        file = Path(file)
        next if file.directory? or SUB_EXTENSIONS.include?(file.ext)
        next puts "Skipping: #{file}" if SUB_EXTENSIONS.any? { |ext|
          f = file.sub_ext(ext) and f.exist? and !f.empty?
        }
        download_subtitles_for_file(file, options)
      }
    end

    def download_subtitles_for_file(file, options)
      begin
        show, season, episode = FilenameParser.parse(file)
        puts file
        success = Downloader::DOWNLOADERS.find { |downloader_class|
          try_downloader(downloader_class.new(file, show, season, episode, options[:lang]))
        }
        error "\nNo downloader could find subtitles for #{file}" unless success
      rescue
        error "\nThe download of the subtitles failed for #{file}:"
        error "#{$!.class}: #{$!.message}"
        $stderr.puts $!.backtrace
      end
    end

    def try_downloader(downloader)
      begin
        print "  #{downloader.to_s.ljust(20)}"
        downloader.download
      rescue Suby::NotFoundError => error
        failure "Failed: #{error.message}"
        false
      rescue Suby::DownloaderError => error
        error "Error: #{error.message}"
        false
      else
        success "Found"
        true
      end
    end

    def extract_sub_from_archive(archive, format, file)
      case format
      when :zip
        Zip::ZipFile.open(archive.to_s) { |zip|
          sub = zip.entries.find { |entry|
            entry.to_s =~ /\.#{Regexp.union SUB_EXTENSIONS}$/
          }
          raise "no subtitles in #{archive}" unless sub
          name = file.sub_ext(Path(sub).ext)
          sub.extract(name.to_s)
        }
      else
        raise "unknown archive type (#{archive})"
      end
    ensure
      archive.unlink if archive.exist?
    end
  end
end
