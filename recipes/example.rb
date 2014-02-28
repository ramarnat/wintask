wintask_principal 'Administrator' do
  logon_type :interactive_token
end

wintask_trigger "once" do
  type :delay
  delay 5.minutes
end

wintask_task '/foo' do
  description 'Notepad starts in 5 minutes'
  author 'AuthorName'
  principal 'Administrator'
  trigger 'once'
  command 'notepad.exe'
  action :create
end
