Rails.application.routes.draw do
  get "/" => "auth#login_form"

  get "pages/home" => "pages#home"
  get "pages/home_manager" => "pages#home_manager"
  get "pages/usage"=> "pages#usage"
  get "pages/inquiry" => "pages#inquiry"
  
  get "auth/login" => "auth#login_form"
  post "auth/login" => "auth#login"
  get "auth/logout" => "auth#logout"

  post "/ajax" => "pages#ajax"
  post "/select_day" => "pages#select_day"
  post "/submit_shift" => "pages#submit_shift"
  post "/determine_day" => "pages#determine_day"
  
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end