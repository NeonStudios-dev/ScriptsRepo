#!/bin/sh
git clone https://github.com/neonstudios-dev/pux.git
cd pux
dotnet publish -c Release
chmod +x /home/flamegrowl/RiderProjects/pux/pux/bin/Release/net8.0/linux-x64/publish/pux
sudo mv /home/flamegrowl/RiderProjects/pux/pux/bin/Release/net8.0/linux-x64/publish/pux /bin
