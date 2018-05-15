# test-environment
Build scripts to create a standard test environment for the ETSI Middlebox Hackathon

## Usage Instructions
1. Place all  files in the same directory somewhere. The ones that are currently in use are build-azure-environment-0.1-openssl.ps1 and build-server-0.1-openssl.sh
1. Ensure you have a valid SSH key pair in ~/.ssh/
1. Run build-azure-environment-0.1-openssl.ps1. You'll be prompted to log in to Azure if necessary
1. Wait for about 5 minutes

## Environment Description
When the build script has finished it will have created a resource group containing a virtual network and a single virtual machines (and some associated other resources). The VM is connected to the virtual network and are also directly connected to the internet via a firewall. The DNS address are presented at the end of the script. You can connect to the VM via SSH using the key in ~/.ssh/

## Creating SSH Keys with Putty (Windows)

1. Open the PuTTYgen program.
1. For type of key to generate, select SSH-2 RSA.
1. Click the Generate button.
1. Move your mouse in the area below the progress bar. When the progress bar is full, PuTTYgen generates your key pair.
1. Click the Save public key button to save the private key. This is the key that will get uploaded to the VM by the build script.
1. Click the Save private key button to save the private key. Warning! You must save the private key. You will need it to connect to your VM.

## Creating SSH Keys on Linux/Mac

1. Check for existing keys. If you have one then you can just use that one: `ls ~/.ssh/id_*`
1. If you don't have any keys, then create one with: `ssh-keygen -t rsa -C "your_email@example.com"`
