
actions :create

attribute :path, :kind_of => String, :name_attribute => true
attribute :command, :kind_of => String, :required => true
attribute :author, :kind_of =>String, :default => 'AuthorName'
attribute :description, :kind_of => String
attribute :trigger, :kind_of => String
attribute :principal, :kind_of => String
attribute :version, :kind_of => String
attribute :working_directory, :kind_of => String
attribute :arguments, :kind_of => Array


