# This class provides access levels
# by flags and numerics. It also packs
# and unpacks.
class Access
  # A
  A = 0x1
  # B
  B = 0x2
  # C
  C = 0x4
  # D
  D = 0x8
  # E
  E = 0x10
  # F
  F = 0x20
  # G
  G = 0x40
  # H
  H = 0x80
  # I
  I = 0x100
  # J
  J = 0x200
  # K
  K = 0x400
  # L
  L = 0x800
  # M
  M = 0x1000
  # N
  N = 0x2000
  # O
  O = 0x4000
  # P
  P = 0x8000
  # Q
  Q = 0x10000
  # R
  R = 0x20000
  # S
  S = 0x40000
  # T
  T = 0x80000
  # U
  U = 0x100000
  # V
  V = 0x200000
  # W
  W = 0x400000
  # X
  X = 0x800000
  # Z
  Z = 0x1000000

  # Merges two access classes together.
  #
  # @return [Access] The new access.
  def self.merge(*merges)
    power = 0
    flags = 0
    merges.each do |m|
      next if m.nil?
      power = m.power if m.power > power
      flags |= m.flags
    end
    return Access.new(power, flags)
  end

  # Creates an access class optionally
  # with level and flags.
  #
  # @param [Fixnum] Power
  # @param [Array<Fixnum>] The flags to set
  # @return [Access] The new access instance.
  def initialize(power = 0, *flags)
    @access = 0
    self.power = power if power != 0
    add(*flags)
  end

  # Adds a flag to the access
  #
  # @param [Array<Fixnum>] The flags to add.
  # @return [nil] Nil
  def add(*flags)
    flags.each do |flag|
      if flag.class == String
        flag = lookup(flag)
      end
      @access |= flag
    end
  end

  # Checks for the existence of the given flags.
  #
  # @param [Array<Fixnum>] The flags to check for
  # @return [Bool] True or false
  def has?(*flags)
    flags.each do |flag|
      if flag.class == String
        flag = lookup(flag)
      end
      unless flag & @access != 0
        return false
      end
    end

    return true
  end

  # Shortcut for Access::has?
  #
  # @param [Array<Fixnum>] The flags to check for.
  # @return [Bool] True or false
  def [](*flags)
    return has?(*flags)
  end

  # Checks for the existence of any of the given
  # flags.
  #
  # @param [Array<Fixnum>] The flags to check for
  # @return [Bool] True or false
  def has_any?(*flags)
    flags.each do |flag|
      if flag.class == String
        flag = lookup(flag)
      end
      return true if flag & @access != 0 
    end

    return false
  end

  # Looks up a fixnum represented by the string
  # flag given.
  #
  # @param [String] String flag.
  # @return [Fixnum] The flag integer.
  def lookup(string)
    return 2 ** (string.chr.downcase.ord - ('a'.ord))
  end

  # Compares power with value.
  #
  # @param [Fixnum] Value to check against.
  # @return [Bool] power > value
  def >(value)
    return (@access >> 25) > value
  end

  # Compares power with value.
  #
  # @param [Fixnum] Value to check against.
  # @return [Bool] power < value
  def <(value)
    return (@access >> 25) < value
  end

  # Compares power with value.
  #
  # @param [Fixnum] Value to check against.
  # @return [Bool] power == value
  def ==(value)
    return (@access >> 25) == value
  end

  # Sets the value for power within 0..10000
  #
  # @param [Fixnum] Value of power.
  # @return [nil] Nil
  def power=(value)
    raise ArgumentError, 'Value must be [0..100]' unless (0..100).include?(value)
    @access = flags + (value << 25)
  end

  # Gets the value of power
  #
  # @return [Fixnum] Power
  def power
    return @access >> 25
  end

  # Gets the flags
  #
  # @return [Fixnum] The flags.
  def flags
    return @access & 0x1FFFFFF
  end

end

