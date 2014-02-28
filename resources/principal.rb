

actions :create

attribute :user_id, :kind_of => String, :name_attribute => true
attribute :logon_type, :kind_of => Symbol, :equal_to => [:password, :interactive_token], :required => true
attribute :password, :kind_of => String
attribute :run_level, :kind_of => Symbol, :equal_to => [:least_privilege, :highest_available], :default => :least_privilege


# Covers 0.10.8 and earlier
def initialize(*args)
  super
  @action = :create
end
