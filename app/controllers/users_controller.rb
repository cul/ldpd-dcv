class UsersController < ApplicationController

  before_action :set_user, only: [:show, :edit, :update, :destroy]

  # Note: To log a specific user in manually, use:
  # sign_in User.where(email: 'durst@library.columbia.edu').first, :bypass => true

  # GET /users/do_wind_login
  def do_wind_login

    if user_signed_in?
      redirect_to root_path
    end

    if ! params[:ticketid]

      # Login: Part 1

      # If ticketid is NOT set, this means that the user hasn't gotten to the uni/password login page yet.  Let's send them there.
      # After they log in, they'll be redirected to this page and they'll continue with the authentication.
      redirect_to(WIND_CONFIG['login_uri'] + '?service=' + WIND_CONFIG['realm'] + '&destination=' + URI::escape(request.original_url))

    else

      # Login: Part 2
      # If ticketid is set, we'll use that ticket for login part 2.

      #We'll validate the ticket against the wind server
      full_validate_uri = WIND_CONFIG['validate_uri'] + '?sendxml=1&ticketid=' + params['ticketid']

      uri = URI.parse(full_validate_uri)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE if Rails.env == 'development'

      wind_request = Net::HTTP::Get.new(uri.request_uri)
      response_body = http.request(wind_request).body

      puts 'Response body: ' + response_body.inspect

      user_uni = nil

      if(response_body.start_with?('<'))
        xml_response = Nokogiri::XML(response_body)
        xml_response.remove_namespaces!
        user_uni = xml_response.xpath('/serviceResponse/authenticationSuccess/user').first.text
        user_affiliations = []
        user_affiliation_elements = xml_response.xpath('/serviceResponse/authenticationSuccess/affiliations/affil')
        if user_affiliation_elements.present?
          user_affiliation_elements.each do |affil_element|
            user_affiliations << affil_element.text
          end
        end
      else
        render :inline => 'Received non-xml (likely text-formatted) authentication response, but only an XML response is allowed.'
      end

      if user_uni.present?
        # We've received a uni response.  This is a real uni user.
        # Next, make sure that this user has the required library affiliation (cul.cunix.local:columbia.edu).

        if user_affiliations.include?('cul.cunix.local:columbia.edu')

          possible_user = User.where(email: (user_uni + '@columbia.edu')).first

          # Create new User (in DB) if this one does not exist
          if possible_user.nil?
            random_password = (('a'..'z').to_a + ('A'..'Z').to_a + (0..9).to_a).shuffle[0,12].join # Generate a secure, random password (because it doesn't matter and won't ever be used for uni authentication)
            possible_user = User.create(
              :email => user_uni + '@columbia.edu',
              :password => random_password,
              :password_confirmation => random_password,
              :first_name => user_uni,
              :last_name => 'Columbia',
              :is_admin => false
            )
          end

          # Sign in.
          sign_in possible_user, :bypass => true
          session[:signed_in_using_uni] = true # TODO use this session variable to know when to do a Wind logout upon Devise logout
          #flash[:notice] = 'You are now logged in.'

          if session[:post_login_redirect_url].present?
            redirect_url = session[:post_login_redirect_url]
            session.delete(:post_login_redirect_url)
          else
            redirect_url = root_path
          end

          redirect_to redirect_url, :status => 302
        else
          render :inline => 'Access denied.  Library affiliation is required.'
          #redirect_to(WIND_CONFIG['logout_uri'] + '?passthrough=1&destination=' + URI::escape(root_url))
        end

      else
        render :inline => 'Wind Authentication failed, Please try again later.'
      end

    end

  end

  # GET /users
  # GET /users.json
  def index
    @users = User.all
  end

  # GET /users/1
  # GET /users/1.json
  def show
  end

  # GET /users/new
  def new
    @user = User.new
  end

  # GET /users/1/edit
  def edit
  end

  # POST /users
  # POST /users.json
  def create
    @user = User.new(user_params)

    respond_to do |format|
      if @user.save
        format.html { redirect_to @user, notice: 'User was successfully created.' }
        format.json { render action: 'show', status: :created, location: @user }
      else
        format.html { render action: 'new' }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /users/1
  # PATCH/PUT /users/1.json
  def update
    respond_to do |format|
      if @user.update(user_params)
        format.html {
          if params[:change_password]
            redirect_to edit_user_url(@user), notice: 'Password successfully updated.'
          else
            redirect_to @user, notice: 'User was successfully updated.'
          end
        }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /users/1
  # DELETE /users/1.json
  def destroy

    # Before deleting a user, verify that at least one admin user still exists
    if(User.where(is_admin: true).where.not(id: @user.id).count == 0)
      flash[:alert] = 'You cannot delete the only remaining admin user.'
    else
      @user.destroy
    end

    respond_to do |format|
      format.html { redirect_to users_url }
      format.json { head :no_content }
    end

  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_user
    @user = User.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def user_params
    params.require(:user).permit(:email, :first_name, :last_name, :password, :password_confirmation, :current_password, :is_admin)
  end

end
