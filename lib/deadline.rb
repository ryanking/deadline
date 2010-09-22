module Deadline extend self
  class Error < StandardError; end

  def deadline(time)
    Thread.current[:deadlines] ||= []
    Thread.current[:deadlines] << (Time.now + time)
    yield
  ensure
    Thread.current[:deadlines] = []
  end

  def remaining
    (Thread.current[:deadlines] && Thread.current[:deadlines].length > 0) ? Thread.current[:deadlines].last - Time.now : nil
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
