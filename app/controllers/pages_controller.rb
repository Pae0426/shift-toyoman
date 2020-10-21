class PagesController < ApplicationController
  before_action :set_login_user
  before_action :ensure_login

  def ensure_login
    if @login_user == nil
      flash[:notice] = "ログインしてください"
      redirect_to("/")
    end
  end
  
  def home
    #シフト情報インスタンス変数
    @shift_this_month = ThisMonth.find_by(user_id: @login_user.user_id)
    @shift_next_month = NextMonth.find_by(user_id: @login_user.user_id)

    now = Time.new #今月Timeクラス
    weeks = ['日', '月', '火', '水', '木', '金', '土']
    this_year = now.year #今年
    this_month = now.month #今月
    today = now.day #今日
    this_beginning_month_day = now.beginning_of_month #月初
    this_end_month_day = now.end_of_month.day #月末
    next_ = now.next_month #翌月Timeクラス
    next_month = next_.month #翌月
    next_beginning_month_day = next_.beginning_of_month #翌月月初
    next_end_month_day = next_.end_of_month.day #翌月月末
    if this_month == 1
      prev_end_month_day = Time.new(this_year - 1, 12).end_of_month.day
    else
      prev_end_month_day = Time.new(this_year, this_month - 1).end_of_month.day
    end
    
    #月替り時
    month_changed = false
    File.open("./app/views/pages/month.txt", "r") do |f|
      f.each_line do |line|
        unless line.to_s.gsub(/\R/, "") == this_month.to_s
          month_changed = true
          shift_all_next_month = NextMonth.all.order(user_id: "ASC")

          #ThisMonthの値をNextMonthに変えてNextMonthを白紙に
          shift_all_next_month.each do |user_next_month|
            user_this_month = ThisMonth.find_by(user_id: user_next_month.user_id)
            for day in 1..31
              day_sym = ("day" + day.to_s).to_sym
              user_this_month[day_sym] = user_next_month[day_sym]
              user_next_month[day_sym] = ""
            end
            user_next_month.save
            user_this_month.save
          end
        end
      end
    end
    if month_changed
      File.open("./app/views/pages/month.txt", "w") do |f|
        f.puts(this_month)
      end
      File.open("./app/views/pages/confirmed.txt", "w") do |f|
        f.puts("not")
      end
    end
    
    #日付情報インスタンス変数
    @month_info = {
      weeks: weeks,
      this_year: this_year,
      this_month: this_month,
      today: today,
      this_beginning_month_day: this_beginning_month_day,
      this_end_month_day: this_end_month_day,
      prev_end_month_day: prev_end_month_day,
      next_month: next_month,
      next_beginning_month_day: next_beginning_month_day,
      next_end_month_day: next_end_month_day
    }
    

    gon.login_user_id = @login_user.user_id
    gon.month_info = @month_info
    gon.next_end_month_day = next_end_month_day
    

    if @login_user.user_id == 1
      redirect_to action: :home_manager, month_info: @month_info, data: {"turbolinks" => false}
    end

    @submit_or_confirmed = "提出"

    File.open("./app/views/pages/confirmed.txt", "r") do |f|
      f.each_line do |line|
        if line.to_s.gsub(/\R/, "") == "confirmed"
          @submit_or_confirmed = "表"
        end
      end
    end
  end

  def home_manager
    @shift_all_next_month = NextMonth.all.order(user_id: "ASC")
    @shift_all_this_month = ThisMonth.all.order(user_id: "ASC")
    gon.login_user_id = @login_user.user_id
    gon.employee_count = @shift_all_next_month.length
    gon.next_end_month_day = params[:month_info][:next_end_month_day]

    @user_id_name = {}
    users = User.all.order(user_id: "ASC")
    
    users.each do |user|
      user_id_sym = user.user_id.to_s.to_sym
      @user_id_name[user_id_sym] = user.name
    end
    @month_info = params[:month_info]
  end


  def ajax
    @user = User.find_by(user_id: 7)

    respond_to do |format|
      format.html 
      format.json {render json: {id: @user.name}}
    end
  end

  def submit_shift
    submit_user = NextMonth.find_by(user_id: @login_user.user_id)
    params[:submit_shift].each do |day, shift_time|
      submit_user[day.to_sym] = shift_time
      submit_user.save
    end
    respond_to do |format|
      format.html 
      format.json {render action: :home, json: {judge: 'success!'}}
    end
  end

  def select_day
    login_user_id = @login_user.user_id

    confirmed = false
    @submit_or_confirmed = "提出"
    File.open("./app/views/pages/confirmed.txt", "r") do |f|
      f.each_line do |line|
        if line.to_s.gsub(/\R/, "") == "confirmed"
          confirmed = true
          @submit_or_confirmed = "表"
        end
      end
    end
    if confirmed
      users = NextMonth.all
    else
      users = NextMonth.where("user_id >= ?", 5)
    end
    users_id = users.select('user_id')
    users_shift = {}
    day_sym = params[:day].to_s.to_sym
    users.each do |user|
      user_id_sym = user.user_id.to_s.to_sym
      name = User.find_by(user_id: user.user_id).name
      shift = user[day_sym]
      users_shift[user_id_sym] = {name: name, shift: shift}
    end
    respond_to do |format|
      format.html 
      format.json {render json: {
          login_user_id: login_user_id,
          users_shift: users_shift,
          confirmed: confirmed,
        }
      }
    end
  end

  def determine_day
    users = ThisMonth.where.not("#{params[:day]} LIKE ?", "NULL")
    users_id = users.select('user_id')
    users_shift = {}
    day_sym = params[:day].to_s.to_sym
    users.each do |user|
      user_id_sym = user.user_id.to_s.to_sym
      name = User.find_by(user_id: user.user_id).name
      shift = user[day_sym]
      users_shift[user_id_sym] = {name: name, shift: shift}
    end
    respond_to do |format|
      format.html 
      format.json {render json: {
          users_shift: users_shift,
        }
      }
    end
  end

  def confirm_shift
    File.open("./app/views/pages/confirmed.txt", "w") do |f|
      f.puts("confirmed")
    end

    employee = User.find_by(name: params[:confirm_shift]["name"])
    employee_id = employee.user_id.to_i
    confirm_user = NextMonth.find_by(user_id: employee_id)
    
    params[:confirm_shift]["shift"].each do |day, shift_time|
      confirm_user[day.to_sym] = shift_time
      confirm_user.save
    end


    respond_to do |format|
      format.html 
      format.json {render action: :home, json: {
          result: "OK",
        }
      }
    end
  end

  def usage
  end

  def inquiry
  end

  def send_inquiry
    File.open("./app/views/pages/inquiry.txt", "a") do |f|
      f.puts(params[:inquiry_message])
    end
  end

  def change_password

  end

  def changed_password
    user = User.find_by(user_id: @login_user.user_id)
    if params[:new_password]  ==  params[:re_new_password]
      user.update(password: params[:new_password])
      user.save
      flash[:changed] = "パスワードを変更しました！"
    else
      flash[:error] = "確認用パスワードと一致しません"
    end

    redirect_to "/pages/change_password"
  end
end
