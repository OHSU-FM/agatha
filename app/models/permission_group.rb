class PermissionGroup < ActiveRecord::Base
  has_many :users, inverse_of: :permission_group
  has_many :permission_ls_groups,
    inverse_of: :permission_group,
    dependent: :destroy,
    after_add: :dirty_user_ls_lists
  # has_many :role_aggregates, through: :lime_surveys

  accepts_nested_attributes_for :permission_ls_groups, allow_destroy: true,
    reject_if: :all_blank
  validates_associated :permission_ls_groups
  attr_accessible :permission_ls_groups_attributes, allow_destroy: true
  attr_accessible :title, :user_ids
  validates :title, presence: true, uniqueness: true

  rails_admin do
    navigation_label "Permissions"
    list do
      field :id
      field :title
      field :users
    end
    edit do
      field :title, :string
      field :users
      field :permission_ls_groups do
        label "Surveys"
      end
    end
  end

  def dirty_user_ls_lists plsg
    users.each {|u| u.dirty_ls_list }
  end

  ##
  # Calculate the role_aggregate that this user can see
  def role_aggregates_for user
    role_aggregates
  end
end
