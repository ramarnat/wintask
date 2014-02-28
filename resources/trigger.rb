

actions :create

attribute :name, :kind_of => String, :name_attribute => true
attribute :type, :kind_of => Symbol, :equal_to => [:delay], :required => true, :default => :delay
attribute :delay


def start_time
  case @type
  when :delay
    return Time.now + @delay
  else
    raise 'Unknown Type of Trigger'
  end
end

def start_time_xmlschema
  start_time.xmlschema
end

def end_time_xmlschema
  (start_time + 1.day).xmlschema
end

# Covers 0.10.8 and earlier
def initialize(*args)
  super
  @action = :create
end
