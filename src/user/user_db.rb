# Keeps a list of known users.
class UserDb
  # Creates a new UserDb.
  #
  # @return [UserDb] The user db.
  def initialize
    @users = []
    @cache = {}
    @nick_cache = {}
  end

  # Adds a user to the collection.
  #
  # @param [User] The user to add.
  # @return [nil] Nil
  def add(user)
    @users.push(user)
  end

  # Removes a user from the collection
  #
  # @param [User] The user to remove.
  # @return [nil] Nil
  def remove(user)
    @users.delete(user)
  end

  # Removes a user by host from the collection.
  #
  # @param [String] The host to search for.
  # @return [nil] Nil
  def remove_host(host)
    user = find(host)
    remove(user) unless user.nil?
  end

  # Wipes all the state from the
  # user objects so that they're fresh
  # on load.
  #
  # @return [nil] Nil
  def prepare_for_serialization
    newusers = []
    @users.each do |u|
      unless u.stateonly
        newusers.push(u)
        u.wipe_all_state
      end
    end

    @users = newusers
    flush_cache
  end

  # Finds a user in the @users array
  # using a fullhost.
  #
  # @param [String] The full host.
  # @return [User] A user object.
  def [](host)
    return find(host)
  end
  
  # Finds a user in the @users array
  # using a fullhost.
  #
  # @param [String] The full host.
  # @return [User] A user object.
  def find(host)
    cached = @cache[host]
    return cached unless cached.nil?

    @users.each do |u|
      u.each_host do |h|
        if host.match(h)
          @cache[host] = u
          return u
        end
      end
    end

    return nil
  end

  # Finds a user object on a server based
  # on nickname.
  #
  # @param [Symbol] The server to look on.
  # @param [String] The nickname to find.
  # @return [User] A user object.
  def find_by_nick(server_key, nick)
    nick = nick.downcase
    cached = @nick_cache.has_key?(server_key) ? @nick_cache[server_key][nick] : nil
    return cached unless cached.nil?

    @users.each do |u|
      if u[server_key] != nil && u[server_key].nick != nil
        if nick == u[server_key].nick.downcase
          @nick_cache[server_key] = {} unless @nick_cache.has_key?(server_key)
          @nick_cache[server_key][nick] = u
          return u
        end
      end
    end

    return nil
  end

  # Removes the host from the cache.
  #
  # @param [String] The host to invalidate.
  # @return [nil] Nil
  def invalidate_cache(host)
    @cache.delete(host)
  end

  # Removes a server or a nickname from the nick cache.
  #
  # @param [Symbol] The key of the server to invalidate.
  # @param [String] The optional nickname to invalidate.
  # @return [nil] Nil
  def invalidate_nick_cache(server_key, nick = nil)
    if nick == nil
      @nick_cache.delete(server_key)
      return
    end
    if @nick_cache.has_key?(server_key)
      nick = nick.downcase
      @nick_cache[server_key].delete(nick)
    end
  end

  # Flushes the lookup cache.
  #
  # @return [nil] Nil
  def flush_cache
    @cache.clear
    @nick_cache.clear
  end

  attr_reader :users
end

