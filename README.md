# VScode instance for Mojifier Workshop 
This is a tailored version of Visual Studio code, that you can run in the browser to complete the Mojifier workshop. It uses [https://coder.com/](https://github.com/codercom/code-server). 




# Getting Started

## Deploy to Azure  
**Pre-requisite:** you will need an Azure account. You can sign up [here](https://azure.microsoft.com/en-gb/free).  

1. Once you have your Azure account, simply click the button below: 

[![deploy](https://raw.githubusercontent.com/deanobalino/coder-mojifier-workshop/master/azuredeploy.png)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fdeanobalino%2Fcoder-mojifier-workshop%2Fmaster%2Fazuredeploy.json)  

2. Log in to your Azure account and complete the form
    - Create New Resource Group and name it `mojifier-workshop`
    - Choose a region, `West Europe` is recommended
    - Create a password for logging into your instance of Visual Studio Code
    - check the box to agree to the Terms and Conditions

3. Press Purchase.

### Parameters
- `password`: Password to protect and logon to web version of VS Code
- `location`: The Azure region to deploy your resources

### Outputs
- `codeServerURL`: URL to access VS Code in browser

### Deployed Resources
- Microsoft.ContainerInstance/containerGroups
- Microsoft.Storage/storageAccounts
- Microsoft.ResourceGroup

## Run Locally on your machine

**Pre-requisite:** you will need to have Docker installed on your device. You can follow instructions to install [here](https://docs.docker.com/install/). 

1. Once you have docker installed, simply run the below in your terminal:  

    `docker run -p 3000:3000 deanobalino/mojifier  --port=3000 --password=changeme`

    ### Parameters
    - `--password`:  Password to protect and logon to web version of Visual Studio Code

2. You should then be able to access your instance of Visual Studio code at:

    `http://localhost:3000/`

3. Login with the `--password` that you chose when running the container.

