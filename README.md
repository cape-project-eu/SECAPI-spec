# SECA - Sovereign European Cloud API

## Description

An open industry standard, a new Application Programming Interface specification for Cloud Infrastructure Management, paving the way for the EuroStack.

## Features

- Sovereignty, e.g. immunity from foreign government interference keeping API control with founding members
- Common standards reduces costs, e.g. less training, common tooling, faster adoption, …
- Broad provider support will incentivize ISVs to build profitable tools and software ecosystems
- Built-in alignment with EU regulations for resilience, data protection and privacy
- Long-term support of APIs provide reliability and maintainability
- Comparison of compliant providers and increased resources using multiple providers
- Directly address the demand of the public sector to have no vendor lock-in

## Repository structure

```text

|─ /spec                     # Main specification containing API definitions and related resources
│   ├── <name>.<version>.yaml      # Versioned API definition (added manually or using a template)
|   ├── /schemas                   # JSON Schema definitions that are used by the API specifications
|   ├── /templates                 # Template files (.tpl) used for generating OpenAPI YAMLs
|   └── /resources                 # Resource definitions for all pages existing in the OpenAPI
│
├─ /website                   # Website of SECA API
│   ├── /docs                   # Documentation of SECA
│   ├── /scripts                # Scripts to generate all files to construct the website
│   ├── /src                    # Contains all resources to be used in the website
│   └── /static                 # Additional files or utilities
│
├─ Makefile                   # Automation script for generating and validating OpenAPI files
├─ /Config                    # Configuration of linter & quality analysis tool
└─ README.md                  # This file
```

## Generating OpenAPI Files Using Makefile

 The OpenAPI files will be used in the website.

### Prerequisites

- [Go](https://go.dev/doc/install) > 1.24

### Website Setup Instructions

```bash
#git clone
git clone https://github.com/eu-sovereign-cloud/spec.git

cd spec/

# Check your Go version using `go version` and skip the instalation step if it is > 1.24
# Download the specified version of Go.
wget https://go.dev/dl/go1.24.1.linux-amd64.tar.gz

# Add Go binary to PATH
echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
source ~/.bashrc

# Go Version
go version
expected: go version go1.24.1 linux/amd64

# Run the Makefile to generate OpenAPI files
make

# Verify that the `dist/specs` directory contains the generated YAML files
ls dist/specs

# Result
activitylog.v1.yaml    compute.v1.yaml       network.v1.yaml        region.v1.yaml   workspace.v1.yaml
authorization.v1.yaml  loadbalancer.v1.yaml  objectstorage.v1.yaml  storage.v1.yaml
```

## Website Installation

### Requirements

- [Node.js](https://nodejs.org/)

### Instructions

```bash
# Clone the repository
git clone https://github.com/eu-sovereign-cloud/spec.git

cd spec/website

# Install dependencies
npm install

# Generate Website Config
npm run generate-config

# Generate API Docs
npm run gen-api-docs all

# Run it
npm run start

# Expected Result
> docs-site@0.0.0 start
> docusaurus start
[INFO] Starting the development server...
[SUCCESS] Docusaurus website is running at: http://localhost:3000/
✔ Client
  Compiled successfully in 1.12m

client (webpack 5.98.0) compiled successfully

# Navigate to `http://localhost:3000/` in your browser to view the website.

```

## Contributing

All contributors are warmly welcome. If you want to become a new contributor, we are so happy! Just, before doing it, read the tips and guidelines presented in the [dedicated documentation page](./CONTRIBUTING.md).

## License

SECA is distributed under the Apache-2.0 [License](./LICENSE). See License for more information.
