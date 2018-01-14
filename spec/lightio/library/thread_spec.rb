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

    it "return nil if timeout" do
      t = LightIO::Thread.new do
        LightIO.sleep(1)
      end
      expect(t.join(0.00001)).to be_nil
    end

    it "return self if not timeout" do
      t = LightIO::Thread.new do
        LightIO.sleep(0.0001)
      end
      expect(t.join(0.001)).to be == t
    end
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

    it "kill it multi times" do
      t = LightIO::Thread.new {}
      expect(t.alive?).to be_truthy
      expect(t.kill).to be == t
      expect(t.kill).to be == t
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

    it "terminated with exception" do
      t = LightIO::Thread.new {1 / 0}
      t.join rescue nil
      expect(t.status).to be_nil
    end

    it "aborting" do
      t = LightIO::Thread.new {LightIO.sleep}
      t.raise "about"
      expect(t.status).to be == 'abouting'
    end
  end

  describe "#abort_on_exception" do
    it "not nil" do
      expect(LightIO::Thread.abort_on_exception).to_not be_nil
      expect(LightIO::Thread.main.abort_on_exception).to_not be_nil
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

    it "play with beams" do
      t = LightIO::Thread.new {LightIO::Timeout.timeout(0.01) {LightIO::Thread.current}}
      expect(t).to be == t.value
    end

    it "play with fiber" do
      t = LightIO::Thread.new {Fiber.new {LightIO::Thread.current}.resume}
      expect(t).to be == t.value
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
      expect(t1["name"]).to be == "hello"
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

    describe "#key?" do
      it "can only save symbol" do
        t1 = LightIO::Thread.new {LightIO::Thread.current[:name] = "hello"}
        t1.join
        expect(t1.key?(:name)).to be_truthy
        expect(t1.key?(:none)).to be_falsey
      end
    end

    describe "#keys" do
      it "return keys" do
        t1 = LightIO::Thread.new {}
        t1[:name] = 1
        t1[:hello] = true
        expect(t1.keys).to be == [:name, :hello]
      end
    end
  end

  describe "#priority" do
    it "not nil" do
      expect(LightIO::Thread.new {}.priority).to_not be_nil
    end
  end

  describe "#raise" do
    it "raise error will kill a thread" do
      t = LightIO::Thread.new {LightIO.sleep(0.0001)}
      t.raise(ArgumentError)
      expect {t.value}.to raise_error ArgumentError
      expect(t.alive?).to be_falsey
    end
  end

  describe "#run" do
    it "wakeup sleeping thread" do
      result = []
      t = LightIO::Thread.new {result << 1; LightIO::Thread.stop; result << 3}
      t.run
      result << 2
      t.run
      expect(result).to be == [1, 2, 3]
    end

    it 'wakeup dead thread' do
      thr = LightIO::Thread.new {}
      thr.kill
      expect {thr.wakeup}.to raise_error(ThreadError)
    end
  end

  describe "#stop?" do
    it "dead thread" do
      t = LightIO::Thread.new {}
      t.kill
      expect(t.stop?).to be_truthy
    end

    it "sleep thread" do
      t = LightIO::Thread.new {}
      expect(t.stop?).to be_truthy
    end

    it "sleep thread" do
      t = LightIO::Thread.new {LightIO::Thread.current.stop?}
      expect(t.value).to be_falsey
    end
  end

  describe "#thread_variables" do
    it "can only save symbol" do
      t1 = LightIO::Thread.new {LightIO::Thread.current.thread_variable_set(:name, "hello")}
      t2 = LightIO::Thread.new {LightIO::Thread.current.thread_variable_set("name", "hello")}
      t1.join; t2.join
      expect(t1.thread_variable_get(:name)).to be == "hello"
      expect(t1.thread_variable_get("name")).to be == "hello"
      expect(t2.thread_variable_get(:name)).to be == "hello"
    end

    it "belongs to thread scope" do
      t1 = LightIO::Thread.new {
        LightIO::Thread.current.thread_variable_set(:name, "hello")
        Fiber.new {
          expect(t1.thread_variable_get(:name)).to be == "hello"
          t1.thread_variable_set(:name, "in thread scope")
        }.resume
      }
      t1.join
      expect(t1.thread_variable_get(:name)).to be == "in thread scope"
    end

    describe "#thread_variable?" do
      it "can only save symbol" do
        t1 = LightIO::Thread.new {LightIO::Thread.current.thread_variable_set(:name, "hello")}
        t1.join
        expect(t1.thread_variable?(:name)).to be_truthy
        expect(t1.thread_variable?(:none)).to be_falsey
      end
    end

    describe "#thread_variables" do
      it "return keys" do
        t1 = LightIO::Thread.new {}
        t1.thread_variable_set(:name, 1)
        t1.thread_variable_set(:hello, true)
        expect(t1.thread_variables).to be == [:name, :hello]
      end
    end
  end
end

RSpec.describe LightIO::ThreadGroup do
  describe "#list" do
    it "should have more threads than native" do
      expect(Set.new(LightIO::ThreadGroup::Default.list)).to be > Set.new(ThreadGroup::Default.list)
    end

    it "removed if thread dead" do
      thr = LightIO::Thread.new {}
      thr_group = LightIO::ThreadGroup.new
      thr_group.add(thr)
      expect(thr_group.list).to be == [thr]
      thr.kill
      expect(thr_group.list).to be == []
      expect(thr.group).to be == thr_group
    end
  end

  describe "#add" do
    it "add to another group" do
      thr = LightIO::Thread.new {}
      expect(thr.group).to be == LightIO::ThreadGroup::Default
      thr_group = LightIO::ThreadGroup.new
      thr_group.add(thr)
      expect(LightIO::ThreadGroup::Default.list.include?(thr)).to be_falsey
      expect(thr_group.list).to be == [thr]
    end

    it "play with native Thread" do
      thr = LightIO::Thread.main
      thr_group = LightIO::ThreadGroup.new
      thr_group.add(thr)
      expect(LightIO::ThreadGroup::Default.list.include?(thr)).to be_falsey
      expect(thr_group.list).to be == [thr]
      LightIO::ThreadGroup::Default.add(thr)
    end

    it "#enclose" do
      thr = LightIO::Thread.new {}
      expect(thr.group).to be == LightIO::ThreadGroup::Default
      thr_group = LightIO::ThreadGroup.new
      thr_group.enclose
      expect(thr_group.enclosed?).to be_truthy
      expect {thr_group.add(thr)}.to raise_error(ThreadError)
      expect(LightIO::ThreadGroup::Default.list.include?(thr)).to be_truthy
      expect(thr_group.list).to be == []
    end
  end
end