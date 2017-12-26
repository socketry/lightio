require 'spec_helper'

RSpec.describe LightIO::Thread do
  describe "#new" do
    it "execute and return value" do
      t = LightIO::Thread.new do
        1
      end
      expect(t.value).to be == 1
    end
  end


  describe "#fork" do
    it "execute and return value" do
      t = LightIO::Thread.fork do
        1
      end
      expect(t.value).to be == 1
    end
  end

  describe "#join" do
    it "wait executed" do
      result = []
      t = LightIO::Thread.new do
        result << "hello"
      end
      t.join
      expect(result).to be == ["hello"]
    end

    # it "return self if timeout" do
    #   t = LightIO::Thread.new do
    #     LightIO.sleep(1)
    #   end
    #   expect(t.join(0.00001)).to be == t
    # end
  end

  describe "#exit kill terminate" do
    it "exit and dead" do
      t1 = LightIO::Thread.new {}.kill
      t2 = LightIO::Thread.new {}.exit
      t3 = LightIO::Thread.new {}.terminate
      expect(t1.alive?).to be_falsey
      expect(t2.alive?).to be_falsey
      expect(t3.alive?).to be_falsey
    end

    it "kill it" do
      t = LightIO::Thread.new {}
      expect(t.alive?).to be_truthy
      expect(LightIO::Thread.kill(t)).to be == t
      expect(t.alive?).to be_falsey
    end
  end

  describe "#status" do
    it "current thread status is run" do
      expect(Thread.current.status).to be == 'run'
      expect(Thread.new {Thread.current.status}.value).to be == 'run'
    end

    it "sleep if thread blocking" do
      t = LightIO::Thread.new {LightIO.sleep(5)}
      t.join(0.00001)
      expect(t.status).to be == 'sleep'
    end

    it "terminate" do
      t = LightIO::Thread.new {LightIO.sleep(5)}
      t.terminate
      expect(t.status).to be_falsey
    end
  end

  describe "#abort_on_exception" do
    it "not nil" do
      expect(LightIO::Thread.abort_on_exception).to_not be_nil
    end
  end

  describe "#current" do
    it "get current thread" do
      t = LightIO::Thread.new {LightIO::Thread.current}
      expect(t).to be == t.value
    end

    it "return main thread" do
      t = LightIO::Thread.current
      expect(t).to be == LightIO::Thread.main
    end
  end

  describe "#exclusive" do
    it "result correct" do
      result = []
      add_ab = proc do |a, b|
        LightIO::Thread.exclusive do
          result << a
          LightIO.sleep(0.001)
          result << b
        end
      end
      t1 = LightIO::Thread.new {add_ab.call(1, 2)}
      t2 = LightIO::Thread.new {add_ab.call(3, 4)}
      t1.join; t2.join
      expect(result).to be == [1, 2, 3, 4]
    end
  end

  describe "#list" do
    it "return Threads" do
      t1 = LightIO::Thread.new {}
      threads = LightIO::Thread.list
      expect(threads.all?(&:alive?)).to be_truthy
      expect(threads.include?(t1)).to be_truthy
      t1.join
      expect(LightIO::Thread.list.include?(t1)).to be_falsey
    end
  end

  describe "#pass" do
    it "pass" do
      result = []
      t1 = LightIO::Thread.new {result << 1; LightIO::Thread.pass; result << 3}
      t2 = LightIO::Thread.new {result << 2; LightIO::Thread.pass; result << 4}
      t1.join; t2.join
      expect(LightIO::Thread.stop).to be_nil
      expect(result).to be == [1, 2, 3, 4]
    end
  end

  describe "#[]" do
    it "can only save symbol" do
      t1 = LightIO::Thread.new {LightIO::Thread.current[:name] = "hello"}
      t2 = LightIO::Thread.new {LightIO::Thread.current["name"] = "hello"}
      t1.join; t2.join
      expect(t1[:name]).to be == "hello"
      expect(t2[:name]).to be == "hello"
    end

    it "belongs to fiber scope" do
      t1 = LightIO::Thread.new {
        LightIO::Thread.current[:name] = "hello"
        Fiber.new {
          expect(t1[:name]).to be_nil
          t1[:name] = "only in fiber scope"
        }.resume
      }
      t1.join
      expect(t1[:name]).to be == "hello"
    end
  end
end