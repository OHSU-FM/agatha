class User < ActiveRecord::Base
  has_paper_trail :ignore=>[:encrypted_password, :password, :password_confirmation]

  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable,
  # :lockable, :timeoutable and :omniauthable
  devise :ldap_authenticatable, :database_authenticatable, :lockable,
    :recoverable, :rememberable, :trackable, :timeoutable

  # Setup accessible (or protected) attributes for your model
  attr_accessible :email, :is_ldap,
    :password, :password_confirmation,
    :remember_me, :username,
    :user_externals_attributes, :permission_group_id

  attr_accessor :login
  serialize :roles, Array

  belongs_to :permission_group

  has_many :dashboard_widgets, :through=>:dashboard
  has_many :permission_ls_groups, :through=>:permission_group
  has_many :question_widgets, :dependent=>:delete_all
  has_many :user_externals, :dependent=>:delete_all

  has_one :dashboard, :dependent=>:destroy

  accepts_nested_attributes_for :user_externals, :allow_destroy=>true

  validates :username,
    :uniqueness => {
    :case_sensitive => false
  },
  :presence => true
  validates :encrypted_password, presence: true
  validates :email,
    :uniqueness => {
    :case_sensitive => false
  },
  :presence => true
  validates :ls_list_state, inclusion: {
    in: %w(dirty clean),
    message: "%{value} must be one of dirty or clean"
  },
  presence: true

  validate :ldap_cannot_update_password

  def ldap_cannot_update_password
    if is_ldap? && encrypted_password_changed?
      errors.add :password, 'cannot be updated for LDAP users'
      return false
    end
  end

  ##
  # Assign roles to a user like this:
  # user = User.new
  # user.admin = true
  ROLES = {
    # can view assignments that they belong to
    :participant=>0,

    # Piecemeal permissions
    :can_dashboard=>1,
    :can_stats=>1,
    :can_reports=>1,
    :can_lime=>1,
    :can_lime_all=>1,
    :can_view_spreadsheet=>1,
    # Role permissions
    :admin=>25,
    :superadmin=>50
  }

  ROLES.each{|role, i|
    # setter
    define_method("#{role.to_s}=") do |val_str|
      # parse setter value to boolean
      val =  [1, true, '1'].include?(val_str)
      # Update roles
      if val && !self.roles.include?(role)
        self.roles.push(role)
      elsif !val && self.roles.include?(role)
        self.roles.delete( role )
      end
    end

    # ? style getter for ROLES
    define_method("#{role}?") do
      return self.roles.include? role
    end

    # ? _or_higher getter for ROLES
    define_method("#{role}_or_higher?") do
      self.roles.each do |role|
        # Does this role actually exist?
        # log error if not
        unless ROLES.include?(role)
          Rails.logger.error("<#{self.class} id:#{self.id} bad_role:#{role}>")
          next
        end
        return true if ROLES[role] >= i
      end
      return false
    end

    # getter for ROLES
    define_method(role) do
      self.roles.include? role
    end
    attr_accessible role
  }

  def roles_enum
    ROLES.keys
  end

  def title
    self[:full_name] || self[:email]
  end

  def display_name name=full_name
    comma_re = /^\s*(\w{1,20} *[^,]*)+,\s+(\w{1,20}\s*)+$/ # last, first
    if name.nil?
      username
    elsif comma_re === name
      name.split(", ").reverse.join(" ")
    else
      name
    end
  end

  def is_ldap?
    self.is_ldap
  end

  ##
  # Overwrite a method inserted by Devise
  #   This allows us to authenticate with either username or email during login
  #   https://github.com/plataformatec/devise/wiki/How-To:-Allow-users-to-sign-in-using-their-username-or-email-address
  def self.find_for_database_authentication(warden_conditions)
    conditions = warden_conditions.dup
    if login = conditions.delete(:login)
      where(conditions).where(["lower(username) = :value OR lower(email) = :value", { :value => login.downcase }]).first
    else
      where(conditions).first
    end
  end

  ##
  # Generic setter for devise authentication, allow users to use email or login
  def login=(login)
    @login = login
  end
  ##
  # Generic getter for username or email
  def login
    @login || self.username || self.email
  end

  def get_ls_list_state
    ls_list_state
  end

  def dirty_ls_list
    self.ls_list_state = "dirty"
    save!
  end

  def has_dirty_ls_list?
    self.ls_list_state == "dirty"
  end

  def clean_ls_list
    self.ls_list_state = "clean"
    save!
  end

  def has_clean_ls_list?
    self.ls_list_state == "clean"
  end

  ##
  # Rails Admin config
  rails_admin do

    navigation_label 'Permissions'
    weight -5

    ##
    # Default group
    group :account do
      active false
      field :id do
        read_only true
      end
      field :institution do
        read_only true
      end
      field :lime_user do
        read_only true
      end
      field :email
      field :username
      field :full_name
      field :password
      field :password_confirmation
      field :is_ldap
    end

    ##
    # Should be read only
    group :sign_in_details do
      active false
      [:current_sign_in_at, :sign_in_count, :reset_password_sent_at,
       :remember_created_at, :last_sign_in_at, :current_sign_in_ip,
       :last_sign_in_ip].each do |attr|
         field attr
       end
    end

    ##
    # should be read only
    group :forms do
      active false
      field :dashboard
    end

    group :site_permissions do
      active false
      ROLES.each{|key, val|
        field key, :boolean
      }
    end

    group :survey_access do
      active false
      field :permission_group, :belongs_to_association do
        inline_edit false
        inline_add false
      end

      field :user_externals, :has_many_association
      field :ls_list_state, :enum do
        enum do
          ["dirty", "clean"]
        end
        default_value "dirty"
      end
      field :permission_ls_groups do
        read_only true
      end

    end

    edit do
      [
        :current_sign_in_at, :sign_in_count, :reset_password_sent_at,
        :remember_created_at, :last_sign_in_at, :current_sign_in_ip,
        :last_sign_in_ip, :roles_mask
      ].each do |attr|
        configure attr do
          read_only true
        end
      end
    end

    list do
      include_fields :id, :username, :email, :permission_group, :is_ldap, :can_dashboard,
        :admin, :superadmin
      exclude_fields :lime_user, :password, :password_confirmation,
        :user_externals, :current_sign_in_at, :sign_in_count, :permission_ls_groups,
        :reset_password_sent_at, :dashboard, :remember_created_at,
        :last_sign_in_at, :current_sign_in_ip, :last_sign_in_ip,
        :participant, :can_stats, :can_reports, :can_lime, :can_view_spreadsheet, :can_lime_all
    end

    exclude_fields [:roles]

  end

  def role_aggregates
    return @role_aggregates if defined? @role_aggregates
    @role_aggregates = []
    if admin_or_higher?
      sids = LimeExt::API.new().list_surveys().map{|ls| ls["sid"] }
      @role_aggregates = RoleAggregate.select{|ra| sids.include? ra.virtual_survey_sid }
    else
      @role_aggregates = permission_group.present? ? permission_group.role_aggregates_for(self) : []
    end
    return @role_aggregates
  end

  def explain_survey_access
    if admin_or_higher?
      details = ['Admin can see everything']
    elsif permission_group.present?
      details, ra = self.permission_group.explain_role_aggregates_for(self)
      details = details.map{|ra, detail| "#{ra.lime_survey.title}:#{detail}"}.join("<br/>")
    else
      details = ['No permission group set']
    end
    return details.html_safe
  end

  def lime_surveys
    if has_dirty_ls_list? or admin_or_higher? or Redis.current.smembers("user:#{id}:ls_p_list").empty?
      ls_list = role_aggregates.map{|ra| ra.lime_survey }
      unless ls_list.empty?
        Redis.current.sadd("user:#{id}:ls_p_list", ls_list.map{|ls| ls.sid })
      end
      self.clean_ls_list
      ls_list
    else
      sids = Redis.current.smembers("user:#{id}:ls_p_list")
      LimeSurvey.where(sid: sids)
    end
  end

  def lime_surveys_by_most_recent n = nil
    surveys = lime_surveys.sort_by { |s|
      next unless s.lime_data.column_names.include? "submitdate"
      ActiveRecord::Base.connection.execute(
        """
        SELECT submitdate FROM lime_survey_#{s.sid} WHERE submitdate IS NOT null;
        """
      ).max_by{|k, v| next unless v.present?; v.to_date}.values.first.to_date
    }.reverse!
    n.present? ? surveys.first(n) : surveys
  end

  def institution
    email.to_s.partition('@').last
  end

  def to_param
    username.parameterize
  end

  def pinned_survey_groups
    permission_group.present? ? permission_group.pinned_survey_groups : []
  end

  def survey_groups
    permission_group.present? ? permission_group.survey_groups : []
  end
end
