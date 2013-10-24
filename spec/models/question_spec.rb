require 'spec_helper'

describe Question do
  subject {@question}

  context "original_text" do
    before do
      @question = FactoryGirl.create(:question)
    end

    it "no updating the original_text" do
      original_text = @question.original_text
      @question.update_attributes :original_text => original_text + "new"
      @question.reload.original_text.should eql original_text
    end

    its('original_text') { should eq @question.display_text }
  end

  context "validation" do
    before do
      @question = FactoryGirl.build(:question)
    end

    context "display_text" do

      it { should respond_to(:display_text) }
      it { should ensure_length_of(:display_text).
            is_at_least(1).
            is_at_most(140) }
    end

    context "neighborhood" do
      it { should ensure_length_of(:neighbourhood).is_at_most(255) }

      it "is not valid with special characters" do
        @question.neighbourhood = "&dddd"
        @question.should_not be_valid
      end

      it "is valid with letters and spaces" do
        @question.neighbourhood = "Ddddd D"
        @question.should be_valid
      end
    end

    context "name" do
      it { should ensure_length_of(:name).is_at_least(1).is_at_most(255) }

      it "is not valid with special characters" do
        @question.name = "$$%^&*((((dddd"
        @question.should_not be_valid
        @question.errors[:name].first.should eq "only allows letters, spaces, periods, hyphens, apostrophes, and @ signs"
      end

      it "is valid with letters and spaces" do
        @question.name = "Ddddd D"
        @question.should be_valid
      end

      it "is valid with period" do
        @question.name = "abc."
        @question.should be_valid
      end

      it "is valid with hyphens" do
        @question.name = "abc-"
        @question.should be_valid
      end

      it "is valid with apostrophes" do
        @question.name = "abc'"
        @question.should be_valid
      end

      it "is valid with @" do
        @question.name = "abc@"
        @question.should be_valid
      end
    end

    context "email" do
      it { should ensure_length_of(:email).is_at_most(255)}

      it "is not valid with different email confirmation" do
        @question.email = "email@email.com"
        @question.email_confirmation = "email@email.confirmation.com"
        @question.should_not be_valid
      end

      it "is valid with the same email confirmation" do
        @question.email = "email@email.com"
        @question.email_confirmation = "email@email.com"
        @question.should be_valid
      end
    end
  end

  context "display_author" do
    context "when the question is submitted anonymously" do
      it "displays the name" do
        @question = FactoryGirl.build(:question, :anonymous)
        @question.display_author.should == Question::ANONYMOUS
      end
    end

    context "when the question is not submitted anonymously" do
      it "displays the name" do
        @question = FactoryGirl.build(:question)
        @question.display_author.should == @question.name
      end
    end
  end

  describe "in_active_voting_rounds?" do
    context "not in any voting round" do
      it "returns false" do
        @question = FactoryGirl.build(:question)
        @question.in_active_voting_rounds?.should be_false
      end
    end

    context "in one voting round" do
      context "voting round is new" do
        it "returns true" do
          voting_round = FactoryGirl.build(:voting_round,  status:VotingRound::Status::New)
          @question = FactoryGirl.build(:question)
          @question.voting_rounds = [voting_round]

          @question.in_active_voting_rounds?.should be_true
        end
      end
      context "voting round is live" do
        it "return true" do
            voting_round = FactoryGirl.build(:voting_round,  status:VotingRound::Status::Live)
            @question = FactoryGirl.build(:question)
            @question.voting_rounds = [voting_round]

            @question.in_active_voting_rounds?.should be_true
        end
      end
      context "voting round is completed" do
        it "return false" do
            voting_round = FactoryGirl.build(:voting_round,  status:VotingRound::Status::Completed)
            @question = FactoryGirl.build(:question)
            @question.voting_rounds = [voting_round]

            @question.in_active_voting_rounds?.should be_false
        end
      end
      context "voting round is deactivated" do
        it "return false" do
            voting_round = FactoryGirl.build(:voting_round,  status:VotingRound::Status::Deactivated)
            @question = FactoryGirl.build(:question)
            @question.voting_rounds = [voting_round]

            @question.in_active_voting_rounds?.should be_false
        end
      end
    end

    context "in multiple voting rounds" do
      context "none of the voting rounds is new, or live" do
        it "returns false" do
          voting_round1 = FactoryGirl.build(:voting_round,  status:VotingRound::Status::Deactivated)
          voting_round2 = FactoryGirl.build(:voting_round,  status:VotingRound::Status::Completed)
          @question = FactoryGirl.build(:question)
          @question.voting_rounds = [voting_round1, voting_round2]

          @question.in_active_voting_rounds?.should be_false

        end
      end

      context "one of the voting rounds is new" do
        it "returns true" do
          voting_round1 = FactoryGirl.build(:voting_round,  status:VotingRound::Status::Deactivated)
          voting_round2 = FactoryGirl.build(:voting_round,  status:VotingRound::Status::New)
          @question = FactoryGirl.build(:question)
          @question.voting_rounds = [voting_round1, voting_round2]

          @question.in_active_voting_rounds?.should be_true
        end
      end
    end
  end
end

