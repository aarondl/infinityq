# Hosts extensions, unloads them, initializes them
# and manages calls into them.
class ExtensionHost
  # Creates a new ExtensionHost with a load path
  # argument.
  #
  # @param [String] The addition to the load path if any.
  # @param [IrcServer] The IrcServer to load extensions with
  # @param [IrcProtoEvent] The IrcProtoEvent to load extensions with
  # @param [FunctionRegistrar] The FunctionRegistrar to load extensions with
  # @return [ExtensionHost] A new extension host instance.
  def initialize(extension_path, server, irc_proto, fn_registrar)
    @server = server
    @irc_proto = irc_proto
    @fn_registrar = fn_registrar
    @extensions = {}
    @path = extension_path
    if @path != nil
      $:.push extension_path unless $:.include? extension_path
    end
  end

  # Loads the extensions given by the strings.
  #
  # @param [Array<String>, Array<Symbol>] A list of extensions to load.
  # @return [nil] Nil
  def load_extensions(*exts)
    exts.each do |ext|
      load file_name(ext)
      sym = ext_sym(ext)
      obj = Object.const_get(sym).new(@server, @irc_proto, @fn_registrar)
      obj.ext_load if obj.respond_to?(:ext_load)
      @extensions[sym] = obj
    end
  end

  # Unloads a loaded extension.
  #
  # @param [Array<String>, Array<Symbol>] A list of extensions to unload.
  # @return [nil] Nil
  def unload_extensions(*exts)
    exts.each do |ext|
      sym = ext_sym(ext)
      obj = @extensions[sym]
      obj.ext_unload if obj.respond_to?(:ext_unload)
      obj.unload
      Object.send(:remove_const, sym)
      @extensions.delete sym
    end
  end

  # Returns a list of loaded extensions.
  #
  # @return [Array<Symbol>] An array of loaded extensions.
  def extensions
    e = []
    @extensions.each_key do |k|
      e.push k
    end
    return e
  end

  # Gets an extension object by it's name.
  #
  # @param [Symbol] The key to the extension.
  # @return [Object] The extension object.
  def extension(key)
    return nil unless @extensions.has_key?(key)
    return @extensions[key]
  end

  # Converts a class or extension name into a file name.
  #
  # @param [String, Symbol] Name of the extension.
  # @return [String] The file name.
  def file_name(name)
    return name.to_s.downcase + '.rb' if name.kind_of?(Symbol)
    return ext_name(name).downcase + '.rb'
  end

  # Converts an extension name into a file name.
  #
  # @param [String, Symbol] Name of the extension.
  # @return [Symbol] The extension symbol.
  def ext_sym(name)
    return name if name.kind_of?(Symbol)
    return ext_name(name).to_sym
  end

  # Converts an extension name into a class name.
  #
  # @param [String, Symbol] Name of the extension.
  # @return [String] The extension name.
  def ext_name(name)
    return name.to_s if name.kind_of?(Symbol)
    return name.gsub(/\s/, '_')
  end

  # Cleans the load path dirtied by this instance of
  # ExtensionHost.
  #
  # @return [nil] Nil
  def clean_load_path
    $:.delete @path unless @path.nil?
  end

  attr_reader :path
end

