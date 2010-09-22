module Deadline extend self
  class Error < StandardError; end

  def deadline(time)
    #TODO figure out what to do with nested calls
    Thread.current[:deadline] = Time.now + time
    yield
  ensure
    Thread.current[:deadline] = nil
  end

  def remaining
    Thread.current[:deadline] ? Thread.current[:deadline] - Time.now : nil
  end

  def expired?
    remaining <= 0
  end

  def raise
    Kernel.raise Error, "Deadline expired"
  end

  def raise_if_expired
    self.raise if expired?
  end
end
