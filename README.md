# test-environment
Build scripts to create a standard test environment for the ETSI Middlebox Hackathon

## Usage Instructions
1. Place all three script files in the same directory somewhere
1. Ensure you have a valid SSH key pair in ~/.ssh/
1. Run build-azure-environment.ps1. You'll be prompted to log in to Azure if necessary
1. Wait for about 20 minutes

## Environment Description
When the build script has finished it will have created a resource group containing a virtual network and three virtual machines (and some associated other resources). The VMs are all connected to the virtual network and are also directly connected to the internet via a firewall. The DNS addresses are presented at the end of the script. You can connect to the VMs via RDP (for the Windows VM) and via SSH for the others

## Creating SSH Keys with Putty

1. Open the PuTTYgen program.
1. For Type of key to generate, select SSH-2 RSA.
1. Click the Generate button.
1. Move your mouse in the area below the progress bar. When the progress bar is full, PuTTYgen generates your key pair.
1. Click the Save public key button to save the private key. This is the key that will get uploaded to the VM by the build script.
1. Click the Save private key button to save the private key. Warning! You must save the private key. You will need it to connect to your machines.
