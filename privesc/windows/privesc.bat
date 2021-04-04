IF NOT EXIST accesschk64.exe ECHO accesschk64.exe is missing. & EXIT

echo "------ SYSTEM INFO ------" > privesc.txt
systeminfo >> privesc.txt
echo. >> privesc.txt
echo For Win 7/8, execute wmic_info.bat >> privesc.txt
echo "-------------------------------" >> privesc.txt
echo. >> privesc.txt

echo "------ HOSTNAME ------" >> privesc.txt
hostname >> privesc.txt
echo "-------------------------------" >> privesc.txt
echo. >> privesc.txt

echo "------ USERNAME / GROUPS ------" >> privesc.txt
echo %username% >> privesc.txt
net user %username% >> privesc.txt
echo. >> privesc.txt

echo "------ WHO IS ADMIN ? (Administrators group) ------" >> privesc.txt
net localgroup Administrators >> privesc.txt
echo "-------------------------------" >> privesc.txt
echo. >> privesc.txt

echo "------ WHO AM I ? ------" >> privesc.txt
whoami /all >> privesc.txt
echo "-------------------------------" >> privesc.txt
echo. >> privesc.txt

echo "------ ACCOUNTS ------" >> privesc.txt
net users >> privesc.txt
echo "-------------------------------" >> privesc.txt
echo. >> privesc.txt

echo "------ NETWORKS ------" >> privesc.txt
ipconfig /all >> privesc.txt
route print >> privesc.txt
arp -a >> privesc.txt
echo "-------------------------------" >> privesc.txt
echo. >> privesc.txt

echo "------ ACTIVE CONNECTIONS ------" >> privesc.txt
netstat -ano >> privesc.txt
echo. >> privesc.txt
echo Is there some vulnerable services to expose??? >> privesc.txt
echo "-------------------------------" >> privesc.txt
echo. >> privesc.txt

echo "------ FIREWALL CONFIGURATION >= XP SP2 ------" >> privesc.txt
netsh firewall show state >> privesc.txt
netsh firewall show config >> privesc.txt
echo "-------------------------------" >> privesc.txt
echo. >> privesc.txt

echo "------ IS UAC ENABLED ? ------" >> privesc.txt
REG QUERY HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Policies\System\ /v EnableLUA >> privesc.txt
echo "-------------------------------" >> privesc.txt
echo. >> privesc.txt

echo "------ SCHEDULED TASKS ------" >> privesc.txt
schtasks /query /fo LIST /v >> privesc.txt
echo "-------------------------------" >> privesc.txt
echo. >> privesc.txt

echo "------ RUNNING PROCESSES LINKED TO STARTED SERVICES ------" >> privesc.txt
echo "------ sc qc <service_name> for specific service ------" >> privesc.txt
tasklist /SVC >> privesc.txt
powershell "Get-WmiObject win32_process | Select-Object Name,@{n='Owner';e={$_.GetOwner().User}},Status,CommandLine | sort Name" >> privesc.txt
echo "-------------------------------" >> privesc.txt
echo. >> privesc.txt

echo "------ SERVICES STARTED ------" >> privesc.txt
net start  >> privesc.txt
echo "-------------------------------" >> privesc.txt
echo. >> privesc.txt

echo "------ SERVICE WITH UNQUOTED PATHS ------" >> privesc.txt
wmic service get name,displayname,pathname,startmode |findstr /i "auto" |findstr /i /v "c:\windows\\" |findstr /i /v """  >> privesc.txt
echo "-------------------------------" >> privesc.txt
echo. >> privesc.txt

echo "------ DRIVERS INSTALLED ------" >> privesc.txt
driverquery >> privesc.txt
echo "-------------------------------" >> privesc.txt
echo. >> privesc.txt

echo "------ findstr /i /s 'cpassword' C:\*.xml 2>NUL ------" >> privesc.txt
findstr /i /s "cpassword" %ProgramData%\Microsoft\Group Policy\*.xml 2>NUL >> privesc.txt
REM GPP passwords
echo "-------------------------------" >> privesc.txt
echo. >> privesc.txt

echo "------ AlwaysInstallElevated ------" >> privesc.txt
echo "------ allows low privileged users to install programs (.msi) as SYSTEM ------" >> privesc.txt
reg query HKLM\SOFTWARE\Policies\Microsoft\Windows\Installer\AlwaysInstallElevated >> privesc.txt
reg query HKCU\SOFTWARE\Policies\Microsoft\Windows\Installer\AlwaysInstallElevated >> privesc.txt
echo "-------------------------------" >> privesc.txt
echo. >> privesc.txt

echo "------ WEAK FOLDERS PERMISSIONS PER DRIVE (Users, Authenticated Users) ------" >> privesc.txt
accesschk64.exe /accepteula -uwdqs Users c:\ >> privesc.txt
accesschk64.exe /accepteula -uwdqs "Authenticated Users" c:\ >> privesc.txt
echo. >> privesc.txt

echo "------ WEAK FILES PERMISSIONS PER DRIVE (Users, Authenticated Users) ------" >> privesc.txt
accesschk64.exe /accepteula -uwdqs Users c:\ >> privesc.txt
accesschk64.exe /accepteula -uwdqs "Authenticated Users" c:\ >> privesc.txt
echo "-------------------------------" >> privesc.txt
echo. >> privesc.txt

echo "------ WEAK SERVICES PERMISSIONS (Users) ------" >> privesc.txt
accesschk64.exe /accepteula -uwcqv "Users" * >> privesc.txt
echo "-------------------------------" >> privesc.txt
echo. >> privesc.txt

echo "------ WEAK SERVICES PERMISSIONS (Authenticated Users) ------" >> privesc.txt
accesschk64.exe /accepteula -uwcqv "Authenticated Users" * >> privesc.txt
echo "-------------------------------" >> privesc.txt
echo. >> privesc.txt

echo "------ WEAK SERVICES PERMISSIONS (Power Users) ------" >> privesc.txt
accesschk64.exe /accepteula -uwcqv "Power Users" * >> privesc.txt
echo "-------------------------------" >> privesc.txt
echo. >> privesc.txt

echo "------ WEAK SERVICES PERMISSIONS (Remote Desktop Users) ------" >> privesc.txt
accesschk64.exe /accepteula -uwcqv "Remote Desktop Users" * >> privesc.txt
echo "-------------------------------" >> privesc.txt
echo. >> privesc.txt
