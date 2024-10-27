# awsTorBlock

Terraform and Lambda to deploy TOR exits.

## Usage

### Using autovars.tfvars

1. Copy the `autovars.tfvars.sample` to `autovars.tfvars`.
2. Edit `autovars.tfvars` to include your specific values for the variables.

### Using Jinja2 Template

1. Use the `autovars.tfvars.sample.j2` template to generate the `autovars.tfvars` file.
2. Provide the necessary context with your specific values for the variables when rendering the template.

## Deployment

1. Initialize Terraform:
   ```bash
   terraform init
   ```

2. Apply the Terraform configuration:
   ```bash
   terraform apply
   ```

This will deploy the Lambda function and associated resources to block TOR exit nodes.
