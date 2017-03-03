class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new                   # guest user (not logged in)

    alias_action :create, :read, :update, :destroy, :to => :crud
    alias_action :create, :update, :destroy, :to=> :alter

    # Normal admin function
    if user.admin_or_higher?
      admin_users_permissions user
    else
      other_users_permissions user
    end

    # Do not allow people to:
    # - alter the flow of time
    # - change the course of known history
    # - cross the streams. DO NOT CROSS THE STREAMS!
    cannot :alter, PaperTrail::Version
  end

  ##
  # Permissions for admin users
  def admin_users_permissions user
    can :read, :all
    can :access, :rails_admin
    can :update, User do |user|
      !(user.admin? || user.superadmin?)
    end
    can :crud, RoleAggregate
    can :crud, Dashboard
    can :crud, DashboardWidget
    can :crud, QuestionWidget
    can :crud, Dashboard
    if user.superadmin?
      # Super powers!!
      can :debug,  :dashboard
      can :manage, :all
      can :read, :lime_survey_website
    end

  end

  ##
  # Non Admin users
  def other_users_permissions user
    can :update, User, :id=>user.id
    can :read, User, :id=>user.id

    # Allow access to Dashboard functionality
    if user.can_dashboard?
      can :list, Dashboard    # Own dash listed in index
      can :access, Dashboard  # ditto
      can :crud, QuestionWidget , :user_id=>user.id
      can :crud, Dashboard, :user_id=>user.id
    end

    if user.lime_user
      can :access, :lime_server
    end
  end

end
