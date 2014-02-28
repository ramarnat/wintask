

include Windows::Helper


def load_current_resource
  if exists?
    @current_resource = ScheduledTask.get_task(task_name)
  end
end

action :create do
  unless exists? #&& !installed
    Chef::Log.info("Creating the Windows Task #{@new_resource}")
    task = ScheduledTask.scheduler_service.NewTask(nil)
    task.XmlText = builder.to_xml
    ScheduledTask.root_folder.RegisterTaskDefinition(task_name, task, 6, principal.user_id, principal.password, 1, nil)
    new_resource.updated_by_last_action(true)
  else
    Chef::Log.info("The Windows Task #{new_resource} status is #{current_state}")
#     pp @current_resource.LastTaskResult
#     pp @current_resource.LastRunTime
  end
end

private

def current_state
  ScheduledTask.current_state(task_name)
end

def task_name
  ::File.basename(new_resource.name)
end

def exists?
  ScheduledTask.get_task(task_name)
end

# From Knife Core
def tempfile_for_xml
  basename = "wintask-" << rand(1_000_000_000_000_000).to_s.rjust(15, '0') << '.xml'
  filename = ::File.join(Dir.tmpdir, basename)
  ::File.open(filename, 'wb:utf-16le') do |f|
    data = builder.to_xml(:encoding => 'utf-16le')
    f.sync = true
    # need to add the Byte Order Mark as per http://blog.grayproductions.net/articles/miscellaneous_m17n_details
    f << "\uFEFF" << data
  end

  yield filename

  IO.read(filename)
ensure
 ::File.unlink(filename)
end

def trigger
  resource_collection.find(:wintask_trigger => new_resource.trigger)
end

def principal
  resource_collection.find(:wintask_principal => new_resource.principal)
end

def folder
  ::File.dirname(new_resource.path) == '.' ? '/' : ::File.dirname(new_resource.path)
end

def basename
  ::File.basename(new_resource.path)
end

def builder
  builder = Nokogiri::XML::Builder.new do |xml|
    xml.Task('version' => '1.2', 'xmlns' => "http://schemas.microsoft.com/windows/2004/02/mit/task") {
      xml.RegistrationInfo {
        xml.Date Time.now.xmlschema
        xml.Author new_resource.author
        xml.Description new_resource.description unless new_resource.description.nil?
        xml.Version new_resource.version unless new_resource.version.nil?
      }
      xml.Triggers {
        xml.TimeTrigger {
          xml.StartBoundary trigger.start_time_xmlschema
          xml.EndBoundary trigger.end_time_xmlschema
          xml.Enabled 'true'
        }
      }
      xml.Principals {
        xml.Principal('id'=>"Author") {
          xml.UserId "#{principal.user_id}"
          xml.LogonType camel_case(principal.logon_type.to_s)
          xml.RunLevel camel_case(principal.run_level.to_s)
        }
      }
      xml.Settings {
        xml.MultipleInstancesPolicy 'IgnoreNew'
        xml.DisallowStartIfOnBatteries 'false'
        xml.StopIfGoingOnBatteries 'false'
        xml.AllowHardTerminate 'true'
        xml.StartWhenAvailable 'false'
        xml.RunOnlyIfNetworkAvailable 'false'
        xml.IdleSettings {
          xml.StopOnIdleEnd 'true'
          xml.RestartOnIdle 'false'
        }
        xml.AllowStartOnDemand 'true'
        xml.Enabled 'true'
        xml.Hidden 'false'
        xml.RunOnlyIfIdle 'false'
        xml.WakeToRun 'false'
        xml.ExecutionTimeLimit 'P3D'
        xml.DeleteExpiredTaskAfter 'P30D'
        xml.Priority 7
      }
      xml.Actions('Context'=>"Author") {
        xml.Exec {
          xml.Command win_friendly_path(new_resource.command)
          xml.Arguments win_friendly_path(new_resource.arguments.join) unless new_resource.arguments.nil?
          xml.WorkingDirectory win_friendly_path(new_resource.working_directory) unless new_resource.working_directory.nil?
        }
      }
    }
  end
end

# Generates possible effective names for function in Win32 dll (name+A/W),
# camel_case, snake_case and aliases method names
#
def generate_names(name, options={})
  name = name.to_s
  effective_names = [name]
  effective_names += ["#{name}A", "#{name}W"] unless name =~ /[WA]$/
  aliases = ([options[:alias]] + [options[:aliases]]).flatten.compact
  snake_name = options[:snake_name] || snake_case(name)
  camel_name = options[:camel_name] || camel_case(name)
  case snake_name
    when /^is_/
      aliases << snake_name.sub(/^is_/, '') + '?'
    when /^set_/
      aliases << snake_name.sub(/^set_/, '')+ '='
    when /^get_/
      aliases << snake_name.sub(/^get_/, '')
  end
  [snake_name, camel_name, effective_names, aliases]
end

# returns snake_case representation of string
def snake_case(name)
  name.gsub(/([a-z])([A-Z0-9])/, '\1_\2' ).downcase
end

# returns camel_case representation of string
def camel_case(name)
  if name.include? '_'
    name.split('_').map{|e| e.capitalize}.join
  else
    unless name =~ (/^[A-Z]/)
      name.capitalize
    else
      name
    end
  end
end




