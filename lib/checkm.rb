module Checkm
  class Manifest
    def self.parse str, args = {}
      Manifest.new str, args
    end

    attr_reader :version
    attr_reader :entries
    attr_reader :fields
    attr_reader :path

    def initialize checkm, args = {}
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

    def valid?
      @entries.map { |e| e.valid? }.any? { |b| b == false }
    end

  end

  class Entry
    CHUNK_SIZE = 8*1024*1024
    BASE_FIELDS = ['sourcefileorurl', 'alg', 'digest', 'length', 'modtime', 'targetfileorurl']
    attr_reader :values

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

      return digest_alg.hexdigest == digest
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
