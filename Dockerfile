# Build from coder base image
FROM codercom/code-server

# Set working directory to root of the container
WORKDIR /

# Install dev dependencies
RUN apt-get update && apt-get install -y \
	npm \
	nodejs \
    wget \
    curl \
    git \
    bsdtar
RUN apt-get update && apt-get install -y \
    libssl-dev \
    libffi-dev \
    python-dev \
    apt-transport-https \
    lsb-release \
    software-properties-common \
    node-typescript
RUN apt-get update && apt-get install -y npm 
# Install Azure CLI
RUN curl -sL https://packages.microsoft.com/keys/microsoft.asc | \
    gpg --dearmor | \
    tee /etc/apt/trusted.gpg.d/microsoft.asc.gpg > /dev/null
RUN echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli cosmic main" | tee /etc/apt/sources.list.d/azure-cli.list
RUN apt-get update && apt-get install azure-cli


# Install .NET Core SDK (required for azure function core tools)
RUN wget -q https://packages.microsoft.com/config/ubuntu/18.10/packages-microsoft-prod.deb
RUN dpkg -i packages-microsoft-prod.deb
RUN apt-get  -y install apt-transport-https
RUN apt-get update
RUN apt-get  -y install dotnet-sdk-2.2
RUN curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
RUN mv microsoft.gpg /etc/apt/trusted.gpg.d/microsoft.gpg

# Install Azure Functions Core Tools
RUN apt-get update && apt-get  -y install azure-functions-core-tools

# Clone Mojifier Repository
RUN git clone https://github.com/MicrosoftDocs/mslearn-the-mojifier.git

#Install Azure Functions Extension
RUN curl -JL https://marketplace.visualstudio.com/_apis/public/gallery/publishers/ms-azuretools/vsextensions/vscode-azurefunctions/0.15.0/vspackage > func.vxif
RUN bsdtar -xvf func.vxif
RUN mkdir --parents /root/.local/share/code-server/extensions/ms-azuretools.vscode-azurefunctions-0.15.0
RUN mv extension/* /root/.local/share/code-server/extensions/ms-azuretools.vscode-azurefunctions-0.15.0
RUN rm func.vxif
RUN rm extension.vsixmanifest
# Install Azure Account Extension
RUN curl -JL https://marketplace.visualstudio.com/_apis/public/gallery/publishers/ms-vscode/vsextensions/azure-account/0.8.0/vspackage > azAccount.vxif
RUN bsdtar -xvf azAccount.vxif
RUN mkdir --parents /root/.local/share/code-server/extensions/ms-vscode.azure-account-0.8.0
RUN mv extension/* /root/.local/share/code-server/extensions/ms-vscode.azure-account-0.8.0
RUN rm azAccount.vxif
RUN rm extension.vsixmanifest





EXPOSE 3000
EXPOSE 7071

ENTRYPOINT ["code-server", "./mslearn-the-mojifier", "--allow-http"]

