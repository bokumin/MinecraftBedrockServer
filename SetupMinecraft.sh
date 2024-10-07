#!/bin/bash
# Minecraft Server Installation Script - James A. Chambers - https://jamesachambers.com
# Modified for OpenSUSE compatibility

echo "Minecraft Bedrock Server installation script by James A. Chambers"
echo "Modified for OpenSUSE compatibility"
echo "Latest version always at https://github.com/TheRemote/MinecraftBedrockServer"
echo "Don't forget to set up port forwarding on your router!  The default port is 19132"

# Randomizer for user agent
RandNum=$(echo $((1 + $RANDOM % 5000)))

# You can override this for a custom installation directory
DirName=$(readlink -e ~)
if [ -z "$DirName" ]; then
  DirName=~
fi

# Function to read input from user with a prompt
function read_with_prompt {
  variable_name="$1"
  prompt="$2"
  default="${3-}"
  unset $variable_name
  while [[ ! -n ${!variable_name} ]]; do
    read -p "$prompt: " $variable_name </dev/tty
    if [ ! -n "$(which xargs)" ]; then
      declare -g $variable_name=$(echo "${!variable_name}" | xargs)
    fi
    declare -g $variable_name=$(echo "${!variable_name}" | head -n1 | awk '{print $1;}' | tr -cd '[a-zA-Z0-9]._-')
    if [[ -z ${!variable_name} ]] && [[ -n "$default" ]]; then
      declare -g $variable_name=$default
    fi
    echo -n "$prompt : ${!variable_name} -- accept (y/n)?"
    read answer </dev/tty
    if [[ "$answer" == "${answer#[Yy]}" ]]; then
      unset $variable_name
    else
      echo "$prompt: ${!variable_name}"
    fi
  done
}

Update_Scripts() {
  # Remove existing scripts
  rm -f start.sh stop.sh restart.sh fixpermissions.sh revert.sh

  # Download start.sh from repository
  echo "Grabbing start.sh from repository..."
  curl -H "Accept-Encoding: identity" -L -o start.sh https://raw.githubusercontent.com/TheRemote/MinecraftBedrockServer/master/start.sh
  chmod +x start.sh
  sed -i "s:dirname:$DirName:g" start.sh
  sed -i "s:servername:$ServerName:g" start.sh
  sed -i "s:userxname:$UserName:g" start.sh
  sed -i "s<pathvariable<$PATH<g" start.sh

  # Download stop.sh from repository
  echo "Grabbing stop.sh from repository..."
  curl -H "Accept-Encoding: identity" -L -o stop.sh https://raw.githubusercontent.com/TheRemote/MinecraftBedrockServer/master/stop.sh
  chmod +x stop.sh
  sed -i "s:dirname:$DirName:g" stop.sh
  sed -i "s:servername:$ServerName:g" stop.sh
  sed -i "s:userxname:$UserName:g" stop.sh
  sed -i "s<pathvariable<$PATH<g" stop.sh

  # Download restart.sh from repository
  echo "Grabbing restart.sh from repository..."
  curl -H "Accept-Encoding: identity" -L -o restart.sh https://raw.githubusercontent.com/TheRemote/MinecraftBedrockServer/master/restart.sh
  chmod +x restart.sh
  sed -i "s:dirname:$DirName:g" restart.sh
  sed -i "s:servername:$ServerName:g" restart.sh
  sed -i "s:userxname:$UserName:g" restart.sh
  sed -i "s<pathvariable<$PATH<g" restart.sh

  # Download fixpermissions.sh from repository
  echo "Grabbing fixpermissions.sh from repository..."
  curl -H "Accept-Encoding: identity" -L -o fixpermissions.sh https://raw.githubusercontent.com/TheRemote/MinecraftBedrockServer/master/fixpermissions.sh
  chmod +x fixpermissions.sh
  sed -i "s:dirname:$DirName:g" fixpermissions.sh
  sed -i "s:servername:$ServerName:g" fixpermissions.sh
  sed -i "s:userxname:$UserName:g" fixpermissions.sh
  sed -i "s<pathvariable<$PATH<g" fixpermissions.sh

  # Download revert.sh from repository
  echo "Grabbing revert.sh from repository..."
  curl -H "Accept-Encoding: identity" -L -o revert.sh https://raw.githubusercontent.com/TheRemote/MinecraftBedrockServer/master/revert.sh
  chmod +x revert.sh
  sed -i "s:dirname:$DirName:g" revert.sh
  sed -i "s:servername:$ServerName:g" revert.sh
  sed -i "s:userxname:$UserName:g" revert.sh
  sed -i "s<pathvariable<$PATH<g" revert.sh

  # Download clean.sh from repository
  echo "Grabbing clean.sh from repository..."
  curl -H "Accept-Encoding: identity" -L -o clean.sh https://raw.githubusercontent.com/TheRemote/MinecraftBedrockServer/master/clean.sh
  chmod +x clean.sh
  sed -i "s:dirname:$DirName:g" clean.sh
  sed -i "s:servername:$ServerName:g" clean.sh
  sed -i "s:userxname:$UserName:g" clean.sh
  sed -i "s<pathvariable<$PATH<g" clean.sh

  # Download update.sh from repository
  echo "Grabbing update.sh from repository..."
  curl -H "Accept-Encoding: identity" -L -o update.sh https://raw.githubusercontent.com/bokumin/MinecraftBedrockServer/master/update.sh
  chmod +x update.sh
  sed -i "s<pathvariable<$PATH<g" update.sh
}

Update_Service() {
  # Update minecraft server service
  echo "Configuring Minecraft $ServerName service..."
  sudo curl -H "Accept-Encoding: identity" -L -o /etc/systemd/system/$ServerName.service https://raw.githubusercontent.com/TheRemote/MinecraftBedrockServer/master/minecraftbe.service
  sudo chmod +x /etc/systemd/system/$ServerName.service
  sudo sed -i "s:userxname:$UserName:g" /etc/systemd/system/$ServerName.service
  sudo sed -i "s:dirname:$DirName:g" /etc/systemd/system/$ServerName.service
  sudo sed -i "s:servername:$ServerName:g" /etc/systemd/system/$ServerName.service
  if [ -e server.properties ]; then
    sed -i "/server-port=/c\server-port=$PortIPV4" server.properties
    sed -i "/server-portv6=/c\server-portv6=$PortIPV6" server.properties
  fi

  sudo systemctl daemon-reload

  echo -n "Start Minecraft server at startup automatically (y/n)?"
  read answer </dev/tty
  if [[ "$answer" != "${answer#[Yy]}" ]]; then
    sudo systemctl enable $ServerName.service
    # Automatic reboot at 4am configuration
    TimeZone=$(cat /etc/timezone)
    CurrentTime=$(date)
    echo "Your time zone is currently set to $TimeZone.  Current system time: $CurrentTime"
    echo "You can adjust/remove the selected reboot time later by typing crontab -e or running SetupMinecraft.sh again."
    echo -n "Automatically restart and backup server at 4am daily (y/n)?"
    read answer </dev/tty
    if [[ "$answer" != "${answer#[Yy]}" ]]; then
      croncmd="$DirName/minecraftbe/$ServerName/restart.sh 2>&1"
      cronjob="0 4 * * * $croncmd"
      (
        crontab -l | grep -v -F "$croncmd"
        echo "$cronjob"
      ) | crontab -
      echo "Daily restart scheduled.  To change time or remove automatic restart type crontab -e"
    fi
  fi
}

Fix_Permissions() {
  echo "Setting server file permissions..."
  sudo ./fixpermissions.sh -a >/dev/null
}

Check_Dependencies() {
  # Install dependencies required to run Minecraft server in the background
  echo "Checking and installing dependencies..."
  sudo zypper refresh
  sudo zypper update -y

  # Install required packages
  sudo zypper install -y curl unzip screen net-tools-deprecated gawk openssl pigz libcurl4 libopenssl1_1

  # Check for ARM architecture
  if [[ $(uname -m) == *"aarch"* || $(uname -m) == *"arm"* ]]; then
    echo "ARM architecture detected. Installing additional dependencies..."
    sudo zypper install -y qemu-linux-user qemu-tools binfmt-support
  fi

  # Double check curl installation
  if ! command -v curl &>/dev/null; then
    sudo zypper install -y curl
  fi
}

Update_Server() {
   CURRENT_DIR=$(pwd)

   # Create the downloads directory if it doesn't exist
   mkdir -p "$CURRENT_DIR/downloads"
   
  # Retrieve latest version of Minecraft Bedrock dedicated server
  echo "Checking for the latest version of Minecraft Bedrock server..."
  curl -H "Accept-Encoding: identity" -H "Accept-Language: en" -L -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.33 (KHTML, like Gecko) Chrome/90.0.$RandNum.212 Safari/537.33" -o downloads/version.html https://minecraft.net/en-us/download/server/bedrock/
  #  DownloadURL=$(grep -o 'https://minecraft.azureedge.net/bin-linux/[^"]*' downloads/version.html)
  DownloadURL=$(grep -o 'https://www.minecraft.net/bedrockdedicatedserver/bin-linux/[^"]*' downloads/version.html)
  DownloadFile=$(echo "$DownloadURL" | sed 's#.*/##')
  echo "$DownloadURL"
  echo "$DownloadFile"

  # Download latest version of Minecraft Bedrock dedicated server
  echo "Downloading the latest version of Minecraft Bedrock server..."
  UserName=$(whoami)
  curl -H "Accept-Encoding: identity" -H "Accept-Language: en" -L -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.33 (KHTML, like Gecko) Chrome/90.0.$RandNum.212 Safari/537.33" -o "downloads/$DownloadFile" "$DownloadURL"
  unzip -o "downloads/$DownloadFile"
}

Check_Architecture() {
  # Check CPU architecture to see if we need to do anything special for the platform the server is running on
  echo "Getting system CPU architecture..."
  CPUArch=$(uname -m)
  echo "System Architecture: $CPUArch"

  # Check for ARM architecture
  if [[ "$CPUArch" == *"aarch"* || "$CPUArch" == *"arm"* ]]; then
    echo "ARM architecture detected. Additional setup may be required."
    # Add ARM-specific setup steps here if needed
  fi

  # Check for x86 (32 bit) architecture
  if [[ "$CPUArch" == *"i386"* || "$CPUArch" == *"i686"* ]]; then
    echo "You are running a 32 bit operating system (i386 or i686) and the Bedrock Dedicated Server has only been released for 64 bit (x86_64). If you have a 64 bit processor, please install a 64 bit operating system to run the Bedrock dedicated server!"
    exit 1
  fi
}

Update_Sudoers() {
  if [ -d /etc/sudoers.d ]; then
    sudoline="$UserName ALL=(ALL) NOPASSWD: /bin/bash $DirName/minecraftbe/$ServerName/fixpermissions.sh -a, /bin/systemctl start $ServerName, /bin/bash $DirName/minecraftbe/$ServerName/start.sh"
    if [ -e /etc/sudoers.d/minecraftbe ]; then
      AddLine=$(sudo grep -qxF "$sudoline" /etc/sudoers.d/minecraftbe || echo "$sudoline" | sudo tee -a /etc/sudoers.d/minecraftbe)
    else
      AddLine=$(echo "$sudoline" | sudo tee /etc/sudoers.d/minecraftbe)
    fi
  else
    echo "/etc/sudoers.d was not found on your system. Please add this line to sudoers using sudo visudo: $sudoline"
  fi
}

# Main script execution starts here

# Check to make sure we aren't running as root
if [[ $(id -u) = 0 ]]; then
  echo "This script is not meant to be run as root. Please run ./SetupMinecraft.sh as a non-root user, without sudo; the script will call sudo when it is needed. Exiting..."
  exit 1
fi

Check_Dependencies

# Check to see if Minecraft server main directory already exists
cd $DirName
if [ ! -d "minecraftbe" ]; then
  mkdir minecraftbe
  cd minecraftbe
else
  cd minecraftbe
  if [ -f "bedrock_server" ]; then
    echo "Migrating old Bedrock server to minecraftbe/old"
    cd $DirName
    mv minecraftbe old
    mkdir minecraftbe
    mv old minecraftbe/old
    cd minecraftbe
    echo "Migration complete to minecraftbe/old"
  fi
fi

# Server name configuration
echo "Enter a short one word label for a new or existing server (don't use minecraftbe)..."
echo "It will be used in the folder name and service name..."

read_with_prompt ServerName "Server Label"

# Remove non-alphanumeric characters from ServerName
ServerName=$(echo "$ServerName" | tr -cd '[a-zA-Z0-9]._-')

if [[ "$ServerName" == *"minecraftbe"* ]]; then
  echo "Server label of minecraftbe is not allowed. Please choose a different server label!"
  exit 1
fi

echo "Enter server IPV4 port (default 19132): "
read_with_prompt PortIPV4 "Server IPV4 Port" 19132

echo "Enter server IPV6 port (default 19133): "
read_with_prompt PortIPV6 "Server IPV6 Port" 19133

if [ -d "$ServerName" ]; then
  echo "Directory minecraftbe/$ServerName already exists!  Updating scripts and configuring service ..."

  # Get username
  UserName=$(whoami)
  cd $DirName
  cd minecraftbe
  cd $ServerName
  echo "Server directory is: $DirName/minecraftbe/$ServerName"

  # Update Minecraft server scripts
  Update_Scripts

  # Service configuration
  Update_Service

  # Sudoers configuration
  Update_Sudoers

  # Fix server files/folders permissions
  Fix_Permissions

  # Setup completed
  echo "Setup is complete.  Starting Minecraft $ServerName server.  To view the console use the command screen -r or check the logs folder if the server fails to start"
  sudo systemctl daemon-reload
  sudo systemctl start "$ServerName.service"

  exit 0
fi

# Create server directory
echo "Creating minecraft server directory ($DirName/minecraftbe/$ServerName)..."
cd $DirName
cd minecraftbe
mkdir $ServerName
cd $ServerName
mkdir downloads
mkdir backups
mkdir logs

Check_Architecture

# Update Minecraft server binary
Update_Server

# Update Minecraft server scripts
Update_Scripts

# Update Minecraft server services
Update_Service

# Sudoers configuration
Update_Sudoers

# Fix server files/folders permissions
Fix_Permissions

# Finished!
echo "Setup is complete.  Starting Minecraft server. To view the console use the command screen -r or check the logs folder if the server fails to start."
sudo systemctl daemon-reload
sudo systemctl start "$ServerName.service"

# Wait up to 30 seconds for server to start
StartChecks=0
while [[ $StartChecks -lt 30 ]]; do
  if screen -list | grep -q "\.$ServerName\s"; then
    break
  fi
  sleep 1
  StartChecks=$((StartChecks + 1))
done

# Force quit if server is still open
if ! screen -list | grep -q "\.$ServerName\s"; then
  echo "Minecraft server failed to start after 30 seconds."
else
  echo "Minecraft server has started.  Type screen -r $ServerName to view the running server!"
fi
