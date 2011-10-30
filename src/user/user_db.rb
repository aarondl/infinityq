# Keeps a list of known users.
class UserDb
  # Creates a new UserDb.
  #
  # @return [UserDb] The user db.
  def initialize
    @users = []
    @cache = {}
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

  # Removes the host from the cache.
  #
  # @param [String] The host to invalidate.
  # @return [nil] Nil
  def invalidate_cache(host)
    @cache.delete(host)
  end

  # Flushes the lookup cache.
  #
  # @return [nil] Nil
  def flush_cache
    @cache.clear
  end

  attr_reader :users
end

