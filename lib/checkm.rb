require 'time'

module Checkm
  CHUNK_SIZE = 8*1024*1024
  def self.checksum file, alg
      digest_alg = case alg
        when nil
          return true
        when /md5/
           Digest::MD5.new if alg == 'md5'
        when /sha1/
        when /sha256/
        when /dir/
          return File.directory? file
        else 
          return false      
      end

      while not file.eof? and chunk = file.readpartial(CHUNK_SIZE)
        digest_alg << chunk
      end
      digest_alg.hexdigest
  end

  class Manifest
    def self.parse str, args = {}
      Manifest.new str, args
    end

    attr_reader :version
    attr_reader :entries
    attr_reader :fields
    attr_reader :path

    def initialize checkm, args = {}
      @args = args
      @version = nil
      @checkm = checkm
      @lines = checkm.split "\n"
      @entries = []
      @eof = false
      @fields= nil
      @path = args[:path]
      @path ||= Dir.pwd
      parse_lines 
      # xxx error on empty entries?
      @lines.unshift('#%checkm_0.7') and @version = '0.7' if @version.nil?

    end

    def valid?
      return true if @entries.empty?
      not @entries.map { |e| e.valid? }.any? { |b| b == false }
    end

    def add path, args = {}
      line = Checkm::Entry.create path, args

      Checkm::Manifest.new [@lines, line].flatten.join("\n"), @args
    end

    def remove path
      Checkm::Manifest.new @lines.reject { |x| x =~ /^@?#{path}/ }.join("\n"), @args
    end

    def to_s
      @lines.join("\n")
    end

    def to_hash
      Hash[*@entries.map { |x| [x.sourcefileorurl, x] }.flatten]
    end

    private

    def parse_lines
      @lines.each do |line|
        case line
          when /^#%/
            parse_header line
	  when /^#/
            parse_comment line
	  when /^$/

	  when /^@/
	    parse_line line     
	  else
	    parse_line line     
	end
      end
    end

    def parse_header line
      case line
        when /^#%checkm/
	  match = /^#%checkm_(\d+)\.(\d+)/.match line
          @version = "#{match[1]}.#{match[2]}" if match
	when /^#%eof/
          @eof = true
	when /^#%fields/
          list = line.split('|')
	  list.shift
	  @fields = list.map { |v| v.strip.downcase }
	when /^#%prefix/

	when /^#%profile/

      end
    end
    
    def parse_comment line

    end

    def parse_line line
      @entries << Entry.new(line, self)
    end

  end

  class Entry
    BASE_FIELDS = ['sourcefileorurl', 'alg', 'digest', 'length', 'modtime', 'targetfileorurl']
    attr_reader :values

    def self.create path, args = {}
      base = args[:base] || Dir.pwd
      alg = args[:alg] || 'md5'
      file = File.new File.join(base, path)

      "%s | %s | %s | %s | %s | %s" % [path, alg, Checkm.checksum(file, alg), File.size(file.path), file.mtime.utc.xmlschema, nil]
    end

    def initialize line, manifest = nil
      @line = line.strip
      @include = false
      @fields = BASE_FIELDS
      @fields = manifest.fields if manifest and manifest.fields
      @values = line.split('|').map { |s| s.strip }
      @manifest = manifest
    end

    def method_missing(sym, *args, &block)
      @values[@fields.index(sym.to_s.downcase) || BASE_FIELDS.index(sym.to_s.downcase)] rescue nil
    end


    def valid?
      return source_exists? && valid_checksum? && valid_multilevel? # xxx && valid_length? && valid_modtime?
    end

    private
    def source
      file = sourcefileorurl
      file = file[1..-1] if file =~ /^@/
      File.join(@manifest.path, file)
    end

    def source_exists?
      return File.exists? source
    end

    def valid_checksum?
      file = File.new source
      checksum = Checkm.checksum(file, alg) 
      checksum === true or checksum == digest
    end


    def valid_length?
      throw NotImplementedError
    end

    def valid_modtime?
      throw NotImplementedError
    end

    def valid_multilevel?
      return true unless sourcefileorurl =~ /^@/

      return Manifest.parse(open(source).read, File.dirname(source))
    end
  end
end
