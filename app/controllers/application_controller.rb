class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  include Admin::SessionsHelper

  def load_categories
    @categories = Category.where(active:true)
  end
end
