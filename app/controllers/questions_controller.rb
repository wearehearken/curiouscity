class QuestionsController < ApplicationController
  before_action :set_question, only: [:show]

  def index
    @questions = Question.all
  end

  def show
  end

  def new
    @question = Question.new
    @categories = Category.all
    @question.display_text = params["display_text"]
    @question.name = params["name"]
    @question.anonymous = params["anonymous"]
    @question.email = params["email"]
    @question.neighbourhood = params["neighbourhood"]
    @question.category_ids = params["category_ids"] || []
    @question.display_text = params["question"]["text"] if params["question"] # TODO: rename 'text' to be 'display_text'

  end

  def create
    @question = Question.new(question_params)

    respond_to do |format|
      if @question.save
        format.html { redirect_to question_url(@question), notice: 'Question was successfully created.' }
      else
        @categories = Category.all
        format.html { render action: 'new' }
      end
    end
  end

  def confirm
    @question = Question.new(question_params)
    @categories = Category.all

    render action: 'new' unless @question.valid?
  end
  private
    def question_params
      params.require(:question).permit(:original_text, :display_text, :name, :anonymous, :email, :email_confirmation, :neighbourhood, :category_ids => [])
    end

    def set_question
      @question = Question.find(params[:id])
    end
end
