# This class wraps a hash for great justice.
class Store
  # Stores a value in the store.
  #
  # @param [Symbol, String] The key to the return object.
  # @param [Object] The return object.
  # @return [nil] Nil
  def store(key, value)
    if @storage.nil?
      @storage = {}
    end
    @storage[key] = value
  end

  # Fetches a value from the store.
  #
  # @param [Symbol, String] The key to the return object.
  # @return [Object] The return object.
  def fetch(key)
    return nil if @storage.nil?
    return @storage[key]    
  end

  # Stores a value in the store.
  #
  # @param [Symbol, String] The key to the return object.
  # @param [Object] The return object.
  # @return [nil] Nil
  def []=(key, value)
    store(key, value)
  end

  # Fetches a value from the store.
  #
  # @param [Symbol, String] The key to the return object.
  # @return [Object] The return object.
  def [](key)
    return fetch(key)
  end
end

