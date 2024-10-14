sudo apt update && sudo apt upgrade

# install metaspoilt framework
curl https://raw.githubusercontent.com/rapid7/metasploit-omnibus/master/config/templates/metasploit-framework-wrappers/msfupdate.erb > msfinstall
chmod +x msfinstall
./msfinstall
rm msfinstall

# install burp suite
wget -O  burpinstall "https://portswigger.net/burp/releases/download?product=community&version=2023.9.1&type=Linux"
chmod +x burpinstall
./burpinstall
rm burpinstall

# install vs code
wget -O vsinstall "https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-x64"
sudo dpkg -i vsinstall
rm vsinstall

# apt packages
sudo apt install default-jdk firefox git gobuster hashcat john nmap python3 sqlmap vim wireshark -y

# git clone repos
mkdir /home/$USER/scripts
cd /home/$USER/scripts

git clone https://github.com/peass-ng/PEASS-ng.git

cd ~
