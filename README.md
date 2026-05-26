# Architectural Decision Records — SMB Cloud Migration

## Architecture Diagram

```mermaid
flowchart LR
    Users((("Users /\nInternet")))

    subgraph OnPrem["On-Premise Datacenter"]
        direction TB
        WS[("Web Server\n(Monolith)")]
        DB[("Database Server\n(SQL)")]
        ES[("Email Server")]
        CGW["Customer Gateway"]
    end

    subgraph VPN["Site-to-Site VPN"]
        direction TB
        VPNTUNNEL["IPSec Tunnel\n(Encrypted)"]
    end

    subgraph AWS["AWS Cloud"]
        direction TB
        VGW["Virtual Private\nGateway"]

        subgraph VPC["VPC — Single Region, 3 Availability Zones"]
            direction TB

            subgraph Public["Public Subnets (x3 AZs)"]
                IGW["Internet Gateway"]
                ALB["Application\nLoad Balancer"]
            end

            subgraph Private["Private Subnets (x3 AZs)"]
                ECS["ECS\n(Containerized API)"]
                Aurora["Aurora Serverless\n(RDS)"]
            end
        end

        CF["CloudFront CDN"]
        S3["S3\n(Static Frontend)"]
    end

    subgraph SaaS["SaaS (Cloud-Native)"]
        M365["Microsoft 365 /\nGoogle Workspace\n(Email, Identity, File Sharing)"]
    end

    %% User traffic
    Users --> CF
    CF --> S3
    CF --> ALB
    ALB --> ECS
    ECS --> Aurora
    IGW --> ALB

    %% VPN connection
    CGW --> VPNTUNNEL --> VGW
    VGW --> VPC

    %% On-premise servers feed VPN
    WS --- CGW
    DB --- CGW

    %% Migration targets (dashed)
    WS -. "Migrate frontend" .-> S3
    WS -. "Migrate API" .-> ECS
    DB -. "Batch ETL" .-> Aurora
    ES -. "Migrate" .-> M365
```

---

## ADR-001: On-Premise to AWS Connectivity via Site-to-Site VPN

**Status:** Accepted

**Context:**
The client requires a secure connection between their on-premise infrastructure and AWS during and after migration. A reliable hybrid connectivity solution is needed to support the transition period and any ongoing on-premise dependencies.

**Decision:**
Use AWS Site-to-Site VPN to connect the on-premise environment to the AWS VPC.

**Alternatives Considered:**
- **AWS Direct Connect:** Provides dedicated, high-bandwidth connectivity with lower latency but requires significantly more lead time to provision, involves higher recurring costs, and requires coordination with a colocation or network provider — overhead not justified for an SMB workload.

**Consequences:**
- Faster setup and lower cost than Direct Connect.
- Traffic runs over the public internet (encrypted via IPSec), which introduces some latency variability.
- Adequate for SMB-scale data transfer volumes; can be upgraded to Direct Connect if bandwidth needs grow.

---

## ADR-002: Multi-AZ VPC with 3 Public and 3 Private Subnets

**Status:** Accepted

**Context:**
The client needs a networking foundation in AWS that provides high availability and disaster recovery without unnecessary complexity or cost.

**Decision:**
Deploy a single-region VPC spanning 3 Availability Zones, with one public and one private subnet per AZ (6 subnets total). Public subnets host internet-facing resources (e.g., load balancers, CloudFront origins); private subnets host application and database tiers.

**Alternatives Considered:**
- **Single-AZ deployment:** Simpler and cheaper, but provides no redundancy against an AZ-level outage — unacceptable for a business-critical workload.
- **Multi-region deployment:** Provides maximum resilience but introduces significant complexity (data replication, latency, cost, failover logic) that is not warranted for an SMB use case.

**Consequences:**
- Multi-AZ placement ensures high availability and meets standard disaster recovery requirements for an SMB.
- The 3-AZ layout aligns with AWS best practices and supports Auto Scaling groups and managed services (RDS, ECS) that distribute across AZs automatically.
- Complexity and cost remain appropriate for the client's scale.

---

## ADR-003: Webserver Migration to CloudFront/S3 (Frontend) and ECS (API)

**Status:** Accepted

**Context:**
The client's existing website is assumed to be a monolithic server handling both frontend and backend concerns. The migration needs to move this workload to AWS with minimal code changes and without the operational burden of managing virtual machines.

**Decision:**
Decompose the monolith into a static JavaScript frontend hosted on S3 and served via CloudFront, and a containerized API backend deployed on Amazon ECS (Elastic Container Service).

**Alternatives Considered:**
- **EC2:** Would replicate the existing monolith in the cloud with the least code change, but perpetuates the operational burden of managing OS patching, scaling, and availability — counter to the goals of cloud migration.
- **AWS Lambda (serverless API):** Offers lower operational overhead and cost at scale, but requires refactoring the existing application code to fit a function-based execution model, which increases migration risk and timeline.
- **AWS Elastic Beanstalk:** Abstracts EC2 management but still ties the architecture to a VM-based model and limits flexibility for future evolution.

**Consequences:**
- Containerizing the existing API is the fastest path to cloud deployment without requiring code refactoring.
- CloudFront/S3 for the frontend decouples static asset delivery from the API, improving performance and scalability.
- ECS provides a managed container platform that handles scheduling and availability without requiring Kubernetes complexity.
- The architecture positions the client for future modernization (e.g., migration to Lambda or EKS) without blocking the initial migration.

---

## ADR-004: Database Migration to Amazon Aurora Serverless

**Status:** Accepted

**Context:**
The client's existing database is assumed to be a standard relational SQL database. The migration target must provide high availability, disaster recovery, and strong performance while reducing operational overhead compared to a self-managed database.

**Decision:**
Migrate the database to Amazon Aurora Serverless (PostgreSQL or MySQL-compatible).

**Alternatives Considered:**
- **Standard Amazon RDS:** Provides managed relational database capabilities but requires pre-provisioning instance sizes and manual scaling — less cost-efficient for variable or unpredictable SMB workloads.
- **NoSQL (e.g., DynamoDB):** Not considered, as the source data is already in a relational SQL format; migrating to a NoSQL model would require significant data modeling changes and application refactoring.

**Consequences:**
- Aurora Serverless automatically scales compute capacity based on load, reducing cost for workloads with variable demand.
- Built-in multi-AZ replication provides high availability and automated failover.
- Aurora's performance characteristics (up to 5x MySQL, 3x PostgreSQL throughput vs. standard RDS) provide headroom for growth.
- Serverless eliminates the need to right-size database instances, reducing ongoing operational decisions.

---

## ADR-005: Database Migration via Batch ETL with Last-Mile Sync

**Status:** Accepted

**Context:**
The client's data must be migrated from their on-premise database to Aurora Serverless with minimal disruption to the business. The datasets are relatively small given the SMB scale of the client.

**Decision:**
Use periodic batch ETL scripts to incrementally load data into the cloud database during the migration period, followed by a final "last-mile" synchronization immediately before the go-live cutover.

**Alternatives Considered:**
- **AWS Database Migration Service (DMS):** A managed service for continuous database replication, but adds cost and operational complexity that is not justified given the small size of the datasets.
- **Direct cutover (single migration event):** Simple to execute but results in extended downtime and carries higher risk if issues arise during the cutover window.
- **Blue/green deployment:** Provides zero-downtime cutover with rollback capability but is significantly more complex to orchestrate for an SMB use case.

**Consequences:**
- Batch ETL allows the cloud database to be validated and tested with real data before go-live, reducing cutover risk.
- The last-mile sync minimizes the data gap between on-premise and cloud at the moment of cutover.
- Custom ETL scripts are simpler and cheaper than DMS for small datasets but require development and testing effort upfront.
- Some downtime during the final sync window should be planned for and communicated to stakeholders.

---

## ADR-006: Email Migration to Microsoft 365 or Google Workspace

**Status:** Accepted

**Context:**
The client currently operates an on-premise email server, which may also provide Active Directory and file sharing services. The migration to cloud email must consolidate email, identity management, and file sharing into a single managed platform.

**Decision:**
Evaluate and migrate to either Microsoft 365 or Google Workspace based on the client's existing environment:
- If the current environment is Microsoft-based (Exchange, Active Directory, Windows file shares), migrate to **Microsoft 365** to leverage existing licenses, minimize user retraining, and enable a direct migration path via Azure AD Connect and Exchange migration tools.
- If the current environment is not Microsoft-based, conduct a formal evaluation of **Microsoft 365 and Google Workspace** based on cost, user preference, and integration requirements.

**Alternatives Considered:**
- **Self-hosted cloud email (e.g., on EC2):** Eliminates the managed service cost but replicates the operational burden of the existing on-premise email server — counter to the goals of the migration.
- **Third-party email providers (e.g., Zoho Mail, Fastmail):** Lower cost options but lack the integrated identity management (SSO, MFA, directory services) and file collaboration features that the client requires as a replacement for their existing server.

**Consequences:**
- Both Microsoft 365 and Google Workspace provide email, identity management (SSO, MFA, directory), and file sharing in a single managed platform, replacing the functionality of the on-premise server.
- Choosing the platform aligned with the client's existing environment minimizes migration complexity and user disruption.
- Both platforms eliminate the operational burden of managing email server infrastructure.
- Licensing costs are predictable on a per-user/month basis.
