require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "Deadline" do

  describe "#deadline" do
    it "should set the deadline" do
      Time.should_receive(:now).once.and_return(12)
      Deadline.deadline(1) do
        Thread.current[:deadlines].should == [13]
      end
    end

    it "should cleanup after itself" do
      Deadline.deadline(1) do
      end
      Thread.current[:deadlines].should == []
    end
  end

  describe "#remaining" do
    it "should do some math" do
      Time.should_receive(:now).once.and_return(12, 12.1, 13)
      Deadline.deadline(0.2) do
        Deadline.remaining.should == 12 + 0.2 - 12.1
        Deadline.remaining.should == 12 + 0.2 - 13
      end
    end
  end

  describe "#expired?" do
    it "should return true at 0 or less" do
      Deadline.should_receive(:remaining).and_return -0.1
      Deadline.expired?.should be_true

      Deadline.should_receive(:remaining).and_return 0
      Deadline.expired?.should be_true
    end
  end

  describe "#raise_if_expired" do
    it "deal with a sleep" do
      lambda do
        Deadline.deadline(0.1) do
          sleep 0.4
          Deadline.raise_if_expired
          flunk
        end
      end.should raise_error(Deadline::Error)
    end

    it "shouldn't raise if it doesn't need to" do
      lambda do
        Deadline.deadline(0.2) do
          sleep 0.1
          Deadline.raise_if_expired
          flunk
        end
      end.should_not raise_error(Deadline::Error)
    end
  end

  describe "nested invocations" do
    describe "#deadline" do
      it "should set each deadline" do
        Time.should_receive(:now).and_return(12, 13, 14, 15)
        Deadline.deadline(10) do
          Thread.current[:deadlines].should == [22]
          Deadline.remaining.should == 9
          Deadline.deadline(5) do
            Thread.current[:deadlines].should == [22, 19]
            Deadline.remaining.should == 4
          end
        end
      end

      it "should pop off nested deadlines" do
        Time.should_receive(:now).and_return(12, 13)
        Deadline.deadline(1) do 
          Thread.current[:deadlines].should == [13]
          Deadline.deadline(1) do
            Thread.current[:deadlines].should == [13, 14]
          end
          Thread.current[:deadlines].should == [13]
        end
      end

      it "should always enforce the (temporally) first deadline" do
        Time.should_receive(:now).and_return(12, 13, 14, 15)
        Deadline.deadline(3) do
          Thread.current[:deadlines].should == [15]
          Deadline.remaining.should == 2
          Deadline.deadline(5) do
            Thread.current[:deadlines].should == [15, 19]
            Deadline.remaining.should == 0
          end
        end
      end
    end
  end
end
