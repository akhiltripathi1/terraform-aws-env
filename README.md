# AWS Environment — Terraform

A self-contained, code-only AWS environment: VPC with public/private subnets
across 2 AZs, NAT gateways, an Application Load Balancer, EC2 app instances
in private subnets, security groups that only allow the traffic they need,
and an encrypted, private S3 bucket. No console clicks — every resource is
declared in `.tf` files.

## Architecture

```
Internet
   │
   ▼
[Internet Gateway]
   │
   ▼
[ALB]  (public subnets, SG: 80/443 from 0.0.0.0/0)
   │
   ▼
[EC2]  (private subnets, SG: 80 from ALB SG only)
   │
   ▼
[NAT Gateway]  →  Internet (outbound only, e.g. yum/dnf updates)

[S3 bucket]  — private, encrypted, versioned, reachable via IAM role 
              (no public access, no hardcoded credentials)
```

- **Networking**: `vpc.tf` — 1 VPC, N public + N private subnets (N =
  `var.az_count`, default 2), 1 Internet Gateway, 1 NAT Gateway per AZ for
  HA egress, separate route tables for public vs private.
- **Security**: `security_groups.tf` — ALB SG open to the internet on
  80/443; app SG only accepts port 80 from the ALB's SG (SG-to-SG
  reference, not CIDR), so instances are unreachable directly from the
  internet even though they have no public IP at all.
- **Compute**: `ec2.tf` — Amazon Linux 2023 instances in private subnets,
  IMDSv2 enforced, encrypted root volume, bootstrapped via `user_data` to
  run a simple Apache "hello" page for smoke-testing the ALB.
- **IAM**: `iam.tf` — instance role with SSM (Session Manager) access
  instead of open SSH, plus least-privilege S3 read/write scoped to the
  one bucket.
- **Load balancing**: `alb.tf` — internet-facing ALB, target group with
  health checks, HTTP listener forwarding to the target group.
- **Storage**: `s3.tf` — bucket with versioning, SSE-AES256 encryption,
  and all four public-access-block settings enabled.
- **Outputs**: `outputs.tf` — ALB DNS name, VPC/subnet/instance IDs,
  bucket name.

## Prerequisites

- Terraform >= 1.5
- An AWS account and credentials available to the AWS provider (env vars,
  `~/.aws/credentials` profile, or an assumed role) with permission to
  create VPC, EC2, ELBv2, IAM, and S3 resources.
- (Optional) An existing EC2 key pair if you want SSH access in addition
  to SSM Session Manager.

## Usage — full lifecycle

### 1. Configure

```bash
cp terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars: region, sizing, key_pair_name, etc.
```

### 2. Initialize

Downloads the AWS and random providers and sets up the working directory.

```bash
terraform init
```

### 3. Validate & format (good hygiene before every apply)

```bash
terraform fmt -recursive
terraform validate
```

### 4. Plan

Always review the plan before applying — this is the step that replaces
"console clicks" with an auditable, reviewable diff.

```bash
terraform plan -out=tfplan
```

### 5. Apply

```bash
terraform apply tfplan
```

Terraform will create, in dependency order: VPC → subnets/IGW/NAT →
route tables → security groups → IAM role/instance profile → EC2
instances → S3 bucket → ALB/target group/listener → target group
attachments.

### 6. Verify

```bash
terraform output alb_dns_name
curl http://$(terraform output -raw alb_dns_name)
```

You should see the "Served by <instance-id> in <az>" page, alternating
between instances as the ALB load-balances requests.

### 7. Make a change (optional, to see the lifecycle in action)

E.g. bump `instance_count` in `terraform.tfvars`, then:

```bash
terraform plan -out=tfplan
terraform apply tfplan
```

Terraform computes a minimal diff — only the new instance and its target
group attachment are added; everything else is left alone.

### 8. Destroy

Tear the whole environment down when you're done, in reverse dependency
order, automatically:

```bash
terraform plan -destroy -out=tfplan.destroy   # review what will be removed
terraform apply tfplan.destroy
# or, non-interactively:
terraform destroy -auto-approve
```

Notes on destroy behavior baked into this config:
- `force_destroy = true` on the S3 bucket (`var.s3_force_destroy`) lets
  `terraform destroy` remove the bucket even if objects were written to
  it during testing — turn this off for any bucket holding real data.
- `enable_deletion_protection = false` on the ALB means destroy won't get
  blocked waiting on a manual console step.
- NAT Gateways and EIPs are destroyed after the resources that depend on
  them, and before the VPC — Terraform's dependency graph handles the
  ordering for you; you never have to sequence this by hand.

After `terraform destroy` completes, confirm nothing billable is left:

```bash
terraform state list   # should be empty
aws ec2 describe-vpcs --filters "Name=tag:Project,Values=demo-env"
```

## Cost note

NAT Gateways and the ALB are the main hourly costs in this stack. For a
short-lived demo, either destroy promptly after testing or drop
`az_count` to 1 to run a single NAT Gateway instead of one per AZ.

## File layout

```
versions.tf              # Terraform + provider version pins, provider config
variables.tf              # all input variables
vpc.tf                    # VPC, subnets, IGW, NAT, route tables
security_groups.tf         # ALB and app security groups
iam.tf                     # instance role, SSM + S3 policies, instance profile
ec2.tf                     # AMI lookup, user_data, EC2 instances
alb.tf                     # ALB, target group, listener, attachments
s3.tf                       # S3 bucket + versioning/encryption/public-access-block
outputs.tf                  # ALB DNS name and resource IDs
terraform.tfvars.example    # copy to terraform.tfvars and edit
```
