import wmi

ip = "1.1.1.1"
username = "UsernameHere"
password = "PasswordHere"
c = wmi.WMI (computer=ip,user=username,password=password)

process_id, return_value = c.Win32_Process.Create (CommandLine="notepad.exe")

#result = process.Terminate ()
