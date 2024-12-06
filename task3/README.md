## Task #3. Secure secrets management in Gitlab CI/CD using HashiCorp Vault

Create Vault policies to control which users or services can access specific secrets.
For example, only production servers have access to production secrets.
Create two types of pipelines that interact with Vault to securely manage secrets

1. Direct Vault integration from Gitlab CI/CD pipeline – pipeline extracts secrets
from Vault and passing them to the deployment stage without exposing in
the code or pipeline configurations

2. Server-side secret retrieval during application runtime - set up the pipeline to
deploy the application without embedding any secrets. Instead, after
deployment, the application will retrieve the necessary secrets from Vault
during its execution

https://gitlab.com/mastering-ci-cd/3task-cicd-resort

https://gitlab.com/mastering-ci-cd/3task-cicd-resort

https://gitlab.com/mastering-ci-cd/3task-cicd-resort
