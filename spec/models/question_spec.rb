=begin
Copyright 2013 WBEZ
This file is part of Curious City.

Curious City is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

Curious City is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with Curious City.  If not, see <http://www.gnu.org/licenses/>.
=end
require 'spec_helper'

describe Question do
  subject { @question }

  describe "original_text" do
    before do
      @question = FactoryGirl.create(:question)
    end

    it "no updating the original_text" do
      original_text = @question.original_text
      @question.update_attributes :original_text => original_text + "new"
      @question.reload.original_text.should eql original_text
    end

    context "when empty" do
      its('original_text') { should eq @question.display_text }
    end

    context "when not empty" do
      it "keeps original text" do
        @question = FactoryGirl.create(:question, original_text: "original",
                                      display_text: "display")
        @question.original_text.should eq "original"
      end
    end
  end

  describe "validation" do
    before do
      @question = FactoryGirl.build(:question)
    end

    describe "display_text" do

      it { should respond_to(:display_text) }
      it { should ensure_length_of(:display_text).
            is_at_least(1).
            is_at_most(2000) }
    end

    describe "neighborhood" do
      it { should ensure_length_of(:neighbourhood).is_at_most(100) }

      it "is valid with letters, spaces,slashes, commas, apostrophes, parentheses, dashes,  and periods" do
        @question.neighbourhood = "Ddddd.(),'-/ D"
        @question.should be_valid
      end
    end

    describe "name" do
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

    describe "email" do
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

      it "does not validate email confirmation if email is blank" do
        @question.email = ""
        @question.email_confirmation = "abc@a.com"
        @question.should_not be_valid
        @question.errors[:email_confirmation].should be_empty
      end
    end
  end

  describe "#display_author" do
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

  describe "#in_active_voting_rounds?" do
    context "when not in any voting round" do
      it "returns false" do
        @question = FactoryGirl.build(:question)
        @question.in_active_voting_rounds?.should be_false
      end
    end

    context "when in one voting round" do
      context "when voting round is new" do
        it "returns true" do
          voting_round = FactoryGirl.build(:voting_round,  status:VotingRound::Status::New)
          @question = FactoryGirl.build(:question)
          @question.voting_rounds = [voting_round]

          @question.in_active_voting_rounds?.should be_true
        end
      end
      context "when voting round is live" do
        it "return true" do
            voting_round = FactoryGirl.build(:voting_round,  status:VotingRound::Status::Live)
            @question = FactoryGirl.build(:question)
            @question.voting_rounds = [voting_round]

            @question.in_active_voting_rounds?.should be_true
        end
      end
      context "when voting round is completed" do
        it "return false" do
            voting_round = FactoryGirl.build(:voting_round,  status:VotingRound::Status::Completed)
            @question = FactoryGirl.build(:question)
            @question.voting_rounds = [voting_round]

            @question.in_active_voting_rounds?.should be_false
        end
      end
      context "when voting round is deactivated" do
        it "return false" do
            voting_round = FactoryGirl.build(:voting_round,  status:VotingRound::Status::Deactivated)
            @question = FactoryGirl.build(:question)
            @question.voting_rounds = [voting_round]

            @question.in_active_voting_rounds?.should be_false
        end
      end
    end

    context "when in multiple voting rounds" do
      context "when none of the voting rounds are new, or live" do
        it "returns false" do
          voting_round1 = FactoryGirl.build(:voting_round,  status:VotingRound::Status::Deactivated)
          voting_round2 = FactoryGirl.build(:voting_round,  status:VotingRound::Status::Completed)
          @question = FactoryGirl.build(:question)
          @question.voting_rounds = [voting_round1, voting_round2]

          @question.in_active_voting_rounds?.should be_false

        end
      end

      context "when one of the voting rounds is new" do
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

  describe ".with_status_and_category" do
    it "filters by status, category, and order by created_at desc" do
      category1 =  FactoryGirl.create(:category)
      category2 = FactoryGirl.create(:category, name: "some-other")
      question1 = FactoryGirl.create(:question, categories: [category1],
                                     status: Question::Status::New,  created_at: 1.day.ago)
      question2 = FactoryGirl.create(:question,
                                     status: Question::Status::New, categories: [category1])
      question3 = FactoryGirl.create(:question,
                                     status: Question::Status::Investigating,
                                     categories: [category1])
      question4 = FactoryGirl.create(:question,
                                     status: Question::Status::New, categories: [category2])
      Question.with_status_and_category([Question::Status::New ], category1.name).should == [question2, question1]
    end

    it "filters by status and order" do
      category1 = FactoryGirl.create(:category)
      category2 = FactoryGirl.create(:category, name: "some-other")

      question1= FactoryGirl.create(:question, categories: [category1],
                                   status: Question::Status::Investigating,
                                   created_at: 1.day.ago)

      question2= FactoryGirl.create(:question, categories: [category2],
                                   status: Question::Status::Investigating,
                                   created_at: 2.days.ago)

      question3= FactoryGirl.create(:question, categories: [category2],
                                   status: Question::Status::New)

      Question.with_status_and_category([Question::Status::Investigating], nil).should == [question1, question2]
    end

  end

  describe ".with_search_text" do
    context "when no category selected" do
      it "returns questions with search text only" do
        question = FactoryGirl.create(:question, display_text: "Whatever you are searching for")
        question2 = FactoryGirl.create(:question)
        Question.with_search_text("searching").should eq [question]
      end
    end

    context "with category selected" do
      it "returns questions with search text based on category" do
        category = FactoryGirl.create(:category, name: "economics")
        question = FactoryGirl.create(:question, display_text: "Whatever you are searching for", categories: [category])
        question2 = FactoryGirl.create(:question , display_text: "searching")
        Question.with_search_text("searching",  category.id).should eq [question]
      end
    end

    context "when user provides a neighborhood" do
      it "returns questions with that neighborhood" do
        category = FactoryGirl.create(:category, name: "economics")
        question = FactoryGirl.create(:question, display_text: "Whatever you are searching for", categories: [category], neighbourhood: "Pilsen")
        question2 = FactoryGirl.create(:question , display_text: "searching")
        Question.with_search_text("Pilsen", category.id).should eq [question]
      end
    end

    context "when user provides a description" do
      it "returns questions with that description" do
        category = FactoryGirl.create(:category, name: "economics")
        question = FactoryGirl.create(:question, display_text: "Whatever you are searching for", categories: [category], description: "describe")
        question2 = FactoryGirl.create(:question , display_text: "searching")
        Question.with_search_text("describe", category.id).should eq [question]
      end
    end

    context "when user provides a note" do
      it "returns questions with that note" do
        category = FactoryGirl.create(:category, name: "economics")
        question = FactoryGirl.create(:question, display_text: "Whatever you are searching for", categories: [category], notes: "note")
        question2 = FactoryGirl.create(:question , display_text: "searching")
        Question.with_search_text("note", category.id).should eq [question]
      end
    end

    context "when user provides a name" do
      it "returns questions with that name" do
        category = FactoryGirl.create(:category, name: "economics")
        question = FactoryGirl.create(:question, display_text: "Whatever you are searching for", categories: [category], name: "Landon")
        question2 = FactoryGirl.create(:question , display_text: "searching")
        Question.with_search_text("Landon", category.id).should eq [question]
      end
    end
  end

  describe ".active?" do
    it "is true when the status is New, Investigating, and Answered" do
      [Question::Status::New, Question::Status::Investigating, Question::Status::Answered].each do |status|
        question = FactoryGirl.build(:question, status: status)
        question.active?.should be_true
      end
    end

    it "is false when the status is Removed" do
      question = FactoryGirl.build(:question, status: Question::Status::Removed)
      question.active?.should be_false
    end
  end

  describe "#answered?" do
    context "when the status is Answered" do
      it "is true" do
        question = Question.new(status: Question::Status::Answered)
        question.answered?.should be_true
      end
    end

    context "when the status is not Answered" do
      it "is false" do
        question = Question.new(status: "something else")
        question.answered?.should be_false
      end
    end
  end

  describe "#investigating?" do
    context "when the status is Investigating" do
      it "is true" do
        question = Question.new(status: Question::Status::Investigating)
        question.investigating?.should be_true
      end
    end

    context "when the status is not Investigating" do
      it "is false" do
        question = Question.new(status: "something else")
        question.investigating?.should be_false
      end
    end

  end

  describe "#previous_question" do
    it "retrieves previous question" do
      previous_question = FactoryGirl.create(:question, :other)
      question = FactoryGirl.create(:question)
      question.previous_question.should == previous_question
    end

    it "does not retrieve removed question" do
      previous_question= FactoryGirl.create(:question, :other)
      removed_question = FactoryGirl.create(:question, :other, status: Question::Status::Removed)
      question = FactoryGirl.create(:question)
      question.previous_question.should eq previous_question
    end
  end

  describe "#next_question" do
    it "retrieves next question" do
      question = FactoryGirl.create(:question)
      next_question = FactoryGirl.create(:question, :other)
      question.next_question.should == next_question
    end

    it "does not retrieve removed question" do
      question = FactoryGirl.create(:question)
      removed_question = FactoryGirl.create(:question, :other, status: Question::Status::Removed)
      next_question = FactoryGirl.create(:question, :other)
      question.next_question.should eq next_question
    end
  end

  describe "tags" do
    context "when tags are updated" do
      it "saves the update time" do
        question = FactoryGirl.create(:question)
        question.tag_list = "something new"
        question.save
        question.tags_updated_at.should_not eq nil
      end
    end
    context "when tags are not updated" do
      it "does not update time" do
        question = FactoryGirl.create(:question)
        question.save
        question.tags_updated_at.should eq nil
      end
    end
  end

  describe "notes" do
    context "when notes are updated" do
      it "saves the update time" do
        question = FactoryGirl.create(:question, notes: nil)
        question.notes = "something new"
        question.save
        question.notes_updated_at.should_not eq nil
      end
    end
    context "when notes are not updated" do
      it "does not update time" do
        question = FactoryGirl.create(:question, notes: nil)
        question.save
        question.notes_updated_at.should eq nil
      end
    end
  end

  describe ".recent_questions" do
    it "returns recent updated questions" do
      @most_recent_questions = [Question.new]
      Question.stub_chain(:order, :limit).and_return(@most_recent_questions)
      Question.recent_questions.should == @most_recent_questions
    end
  end

  describe ".recent_questions_with_updated_tags" do
    it "returns recent updated questions with updated tags" do
      @most_recent_questions_with_updated_tags = [Question.new]
      Question.stub_chain(:order, :where, :limit).and_return(@most_recent_questions_with_updated_tags)
      Question.recent_questions_with_updated_tags.should == @most_recent_questions_with_updated_tags
    end
  end

  describe ".recent_questions_with_updated_notes" do
    it "returns recent updated questions with updated notes" do
      @most_recent_questions_with_updated_notes = [Question.new]
      Question.stub_chain(:order, :where, :limit).and_return(@most_recent_questions_with_updated_notes)
      Question.recent_questions_with_updated_notes.should == @most_recent_questions_with_updated_notes
    end
  end
end
