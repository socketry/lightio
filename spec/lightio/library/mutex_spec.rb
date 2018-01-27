require 'spec_helper'

RSpec.describe LightIO::Mutex do
  describe "#lock" do
    it "can't lock self" do
      m = LightIO::Mutex.new
      m.lock
      expect {m.lock}.to raise_error(ThreadError)
    end

    it "lock works" do
      m = LightIO::Mutex.new
      result = []
      m.lock
      thr = LightIO::Thread.new {
        m.lock
        result << 1
      }
      thr.wakeup
      thr.wakeup
      expect(result).to be == []
      m.unlock
      thr.join
      expect(result).to be == [1]
    end
  end

  describe "#unlock" do
    it "raise if not locked" do
      m = LightIO::Mutex.new
      t = LightIO::Thread.fork do
        m.lock
      end
      t.join
      expect(m.locked?).to be_truthy
      expect {m.unlock}.to raise_error ThreadError
    end
  end

  describe "#owned?" do
    it "correct" do
      m = LightIO::Mutex.new
      m.lock
      t = LightIO::Thread.new do
        m.owned?
      end
      expect(t.value).to be_falsey
      expect(m.owned?).to be_truthy
    end
  end

  describe "#sleep" do
    it "correct" do
      m = LightIO::Mutex.new
      m.lock
      result = []
      t = LightIO::Thread.new {m.lock; result << 1; m.unlock}
      # call run twice to make sure it sleep by lock
      t.run
      t.run
      expect(result).to be == []
      m.sleep(0.0001)
      expect(result).to be == [1]
      expect(m.locked?).to be_truthy
    end
  end

  describe "#synchronize" do
    it "correct" do
      result = []
      m = LightIO::Mutex.new
      t1 = LightIO::Thread.new {m.synchronize {result << 1; LightIO.sleep(0.0001); result << 2;}}
      t2 = LightIO::Thread.new {m.synchronize {result << 3; LightIO.sleep(0.0001); result << 4;}}
      t1.join; t2.join
      expect(m.locked?).to be_falsey
      expect(result).to be == [1, 2, 3, 4]
    end
  end

  describe "#try_lock" do
    it "try_lock" do
      m = LightIO::Mutex.new
      expect(m.try_lock).to be_truthy
      expect(m.try_lock).to be_falsey
    end
  end

  describe LightIO::ConditionVariable do
    it '#wait & #signal' do
      mutex = LightIO::Mutex.new
      resource = LightIO::ConditionVariable.new

      sum = 0

      a = LightIO::Thread.new {
        mutex.synchronize {
          resource.wait(mutex)
          sum *= 2
        }
      }

      b = LightIO::Thread.new {
        mutex.synchronize {
          sum =+ 20
          resource.signal
        }
      }

      a.join
      b.run if a.alive?
      expect(sum).to be == 40
    end

    it '#signal' do
      mutex = LightIO::Mutex.new
      resource = LightIO::ConditionVariable.new

      # not effected
      resource.signal
      resource.signal
      resource.signal

      sum = 0

      a = LightIO::Thread.new {
        mutex.synchronize {
          resource.wait(mutex)
          sum *= 2
        }
      }

      b = LightIO::Thread.new {
        mutex.synchronize {
          sum =+ 20
          resource.signal
        }
      }

      a.join
      b.run if b.alive?
      expect(sum).to be == 40
    end


    it '#boardcast' do
      mutex = LightIO::Mutex.new
      resource = LightIO::ConditionVariable.new

      sum = 0

      a = LightIO::Thread.new {
        mutex.synchronize {
          resource.wait(mutex)
          sum *= 2
        }
      }

      b = LightIO::Thread.new {
        mutex.synchronize {
          resource.wait(mutex)
          sum *= 2
        }
      }

      c = LightIO::Thread.new {
        mutex.synchronize {
          sum += 1
          resource.broadcast
        }
      }

      a.join
      b.join if b.alive?
      c.join if c.alive?
      expect(sum).to be == 4
    end
  end
end