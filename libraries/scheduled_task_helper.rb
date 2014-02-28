module Windows
  module ScheduledTaskHelper

    # Creates an instance of the scheduler
    #
    def scheduler_service
      begin
        @@service ||= begin
          service = WIN32OLE.new('Schedule.Service')
          service.Connect
          service
        end
      rescue WIN32OLERuntimeError => err
        raise Error, err.inspect
      end
    end

    # the folder at the root of the task scheduler
    #
    def root_folder
      scheduler_service.GetFolder("\\")
    end

    # Returns an array of scheduled task names.
    #
    def registered_tasks
      # Get the task folder that contains the tasks.
      taskCollection = root_folder.GetTasks(0)
      array = []
      taskCollection.each do |registeredTask|
        array.push(registeredTask)
      end
      array
    end

    # gets the task
    #
    def get_task(name)
      registered_tasks.find { |t| t.Name == name } unless registered_tasks.nil?
    end

    # Array of states (0-4) based on the constants
    #
    def current_state(name)
      task = get_task(name)
      case
      when task.nil?
        "Not Created"
      when task.State >= 0 && task.State <= 4
        ["Unknown", "Disabled", "Queued", "Ready", "Running"].fetch(task.State)
      when task.State == 3 && task.LastTaskResult == 0
        "Completed"
      end
    end
  end
end


module ScheduledTask
  module_function
  extend Windows::ScheduledTaskHelper
end
