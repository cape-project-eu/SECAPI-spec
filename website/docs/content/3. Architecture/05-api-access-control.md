# API Access Control

API access control manages API access permissions through authentication and authorization mechanisms. It determines:

- Who can access the API
- What actions they can perform
- How access is granted

Core purposes:

1. Data Protection: Prevent unauthorized access to sensitive data
2. System Integrity: Guard against API endpoint misuse
3. Compliance: Meet regulatory requirements
4. Trust: Build user confidence through security

API access control combines identity verification (authentication) with permission management (authorization) using specific protocols and frameworks. Its importance grows with increasing API usage in business operations.

Based on **SECA Standard API Server** we adopted the below architecture:

![API Access Control](@site/static/img/access-control.png)

- More in detail, every request goes to the Control Plane API Server.
  - the first step is to **identify** who the customer is.
  - after authentication, we need to verify if the customer has the necessary **privilege** to perform the request
  - finally, we can **validate** and/or **manipulate** the request to meet domain requirements

# Control Plane API – Authentication and Authorization

## Request Flow

Every request to the Control Plane API Server follows a structured sequence:

1. **Identification** – Determine who the customer is.  
2. **Authentication** – Verify the provided credentials using **JSON Web Tokens (JWT)** ([RFC 7519](https://datatracker.ietf.org/doc/html/rfc7519)).  
3. **Authorization** – Check whether the authenticated customer has the necessary **privileges** to perform the requested action, following the Bearer Token usage defined in [RFC 6750](https://datatracker.ietf.org/doc/html/rfc6750).  
4. **Validation and Manipulation** – Validate the request and, if necessary, transform or enrich it to meet domain requirements.  

## Authentication

All API endpoints require a valid **JWT** to be included in the `Authorization` header using the Bearer scheme, for example:

`Authorization: Bearer <token>`

The JWT validation middleware ensures:

- **Signature verification** – Confirms token integrity.  
- **Expiration check** – Rejects expired tokens.  
- **Scope/role check** – Ensures the token contains required claims for access (see *Authorization*).  

Token issuance and lifecycle management are handled **externally** to this API.  
Clients must obtain valid tokens from the designated **Authentication Service**.  

Requests with missing, expired, or invalid tokens will receive a **401 Unauthorized** response, as defined in [RFC 7235](https://datatracker.ietf.org/doc/html/rfc7235).  

## Authorization

Once authenticated, the system enforces **Authorization** policies:

- **Role-based access control (RBAC)** – Assigns permissions based on customer roles.  
- **Scope-based restrictions** – Limits actions according to claims embedded in the JWT (e.g., `scope`, `role`, or `permissions` fields).  
- **Domain-specific rules** – Ensures that only valid operations aligned with business/domain logic are executed.  

Requests that fail authorization checks will receive a **403 Forbidden** response, as defined in [RFC 7231](https://datatracker.ietf.org/doc/html/rfc7231).  

## Authorization Provider Model

In the common **SECA control plane implementation**, authorization is managed by a **Dedicated Authorization Provider**, which centralizes access control decisions across all resources.

### Key Elements

- **Dedicated Resource Provider** – A centralized service that acts as the authority for all authorization decisions. Instead of each resource managing access controls independently, the provider enforces policies, roles, and permissions globally.  
- **Authorization Policies** – Define permissions granted to users, groups, or services. Policies define **who** (identity) can access **what** (resource) and **how** (permissions such as read, write, or delete). These policies are applied consistently across all resources.  
- **Roles and RBAC** – The provider manages roles such as `Viewer`, `Editor`, or `Administrator`, each with a specific set of permissions. Roles simplify management by grouping permissions and applying them to users, groups, or services.  
- **Access Control Enforcement** – The API enforces policies and roles defined by the provider. When a user or service attempts to access a resource, the provider validates the request against the associated permissions before granting or denying access.  

### Benefits

A centralized Authorization Provider enhances security and governance by:

- Reducing complexity through a single source of truth for access control.  
- Ensuring consistency across all cloud resources.  
- Enabling scalable and efficient management of roles and policies.  

By default each tenant is initialized with the well-known [System Roles](../5. Other/04-system-roles.md) 

### Role

A **role** defines a set of permissions that determine what actions a user or system can perform on specific resources within designated scopes.

Each permission entry consists of:

- **Scopes**:  
  A list of resource paths that restrict where the permissions apply (e.g., `workspaces/production`, `workspaces/develop`).
  
- **Resources**:  
  A list of resource types or specific resource paths to which the permissions apply (e.g., `seca.compute/instances`, `seca.network/networks`).

- **Verbs**:  
  A list of allowed operations (HTTP methods) on the resources, such as `get`, `put`, or `delete`.

Additional metadata can be attached to a role:

- **Labels**:  
  Key/value pairs used to categorize or identify the role (e.g., `env: production`).

- **Annotations**:  
  Human-readable descriptions or additional metadata to support role documentation or management.

- **Extensions**:  
  User-defined key/value pairs that are mutable and allow adding custom metadata or functionality.  
  Extensions are subject to validation by the Cloud Service Provider (CSP), and any value that does not meet validation requirements will be rejected during admission.  

The role does not directly modify resource states but governs access according to the specified permissions.


### RoleAssignment

A **role assignment** associates users or service accounts with specific roles, granting them the permissions defined by those roles within the system.

Each role assignment consists of:

- **Subjects (subs)**:  
  A list of user identifiers or service account names to which the roles are assigned (e.g., `user1@example.com`, `service-account-1`).

- **Roles**:  
  A list of role names that are assigned to the specified subjects (e.g., `project-manager`, `workspace-viewer`).

Additional metadata can be attached to a role assignment:

- **Labels**:  
  Key/value pairs used to categorize or identify the role assignment (e.g., `env: production`).

- **Annotations**:  
  Human-readable descriptions or additional metadata to document the role assignment (e.g., `description: Human readable description`).

- **Extensions**:  
  User-defined key/value pairs that are mutable and allow adding custom metadata or functionality.  
  Extensions are subject to validation by the Cloud Service Provider (CSP), and any value that does not meet validation requirements will be rejected during admission.

The role assignment links subjects to roles, enabling access control based on the permissions defined in the corresponding roles.

## Admission Control

**Admission control** in the SECA API Access Control is a mechanism that intercepts requests to the Control Plane before they are persisted in the database, allowing the SECA CSP to enforce policies, apply security rules, and manage resource allocation. Admission controllers act as "gatekeepers" that can accept, modify, or deny requests based on custom or predefined policies, helping ensure a consistent and secure tenant environment.

Although both **admission control** and **status** involve the Cloud Service Provider (CSP) filling in values, they serve fundamentally different purposes. 
- Admission control occurs at the time of resource creation or update, where the CSP may mutate or validate user input to enforce policy and ensure consistency before the resource is persisted. 
- In contrast, the status section is updated after the resource has been created, reflecting changes based on the user's original intent. Status does not alter the initial request but instead provides an observed view of the resource’s state from the user's perspective. 

> Thus, while admission control modifies user input during request processing, status updates track user-intent outcomes without mutating the resource specification.


Key Concepts of Admission Control are the below listed:

- **Request Interception**: When a user or application sends a request to create, update, delete, or connect to a cloud resource, the Control Plane Cloud API processes it through a sequence of admission controllers. These controllers evaluate the request before it is applied to the cluster.
- **Types of Admission Controllers**:
  - **Validating Controllers**: Validate requests according to certain rules. For example, they might check that a cloud resource requests are within limits defined in the tenant subscription.
  - **Mutating Controllers**: Modify requests as needed. For example, they may inject some metadata or other mandatory fields if they would be skip by the user but are needed in the Resource API specification.

### Validation

Resource validation in SECA ensures that all requests to create or modify resources meet business rules before being processed. While authentication verifies who is making the request and authorization determines if they have permission, validation ensures the request itself is valid and consistent.

#### Common Expression Language (CEL) Validations

SECA implements resource validations using the Common Expression Language (CEL), providing a powerful and flexible way to define validation rules directly in the API specification.

Key Concepts of CEL Validations:

- **Declarative Rules**: Validation rules are defined declaratively in the OpenAPI specification using x-cel-validations extensions
- **Multi-level Validation**: Rules can be applied at both the operation level (for specific actions) and schema level (for resource-wide validations)
- **Rich Expression Support**: CEL supports complex validation scenarios including:
  - Field presence and format validation
  - Cross-field dependencies and relationships
  - Complex business rules and constraints
  - Type validation and coercion

Example validation rule:

```yaml
MetaData:
  x-cel-validations:
    - id: "name_validation"
      description: "Validate MetaData name format"
      constraint: "matches(self.name, '^[a-z0-9][-a-z0-9]*$')"
      error_message: "name must be lowercase alphanumeric and may contain hyphens"

BlockStorage:
  x-cel-validations:
    - id: "block_storage_attachment_validation"
      description: "Ensure block storage volumes are not already attached to other instances"
      constraint: |
        # For each requested volume
        !spec.storage.dataBlockStorageRef.exists(volume,
          resource.instances.exists(instance,
            instance.status.dataBlockStorageRef.exists(attached,
              attached.objectRef == volume.objectRef
            )
          )
        )
      error_message: "One or more block storage volumes are already attached to other instances"
```

### Mutation

In SECA, mutation occurs during the admission control phase as part of resource validation.  
When a request to create or modify a resource is submitted, admission control can both validate the request and mutate it. Mutation involves modifying the incoming request — for example, filling in missing fields with default values, adjusting inputs to meet system constraints, or enforcing naming conventions — before it is persisted.  
This ensures that the resource meets business and system rules without requiring the user to manually correct their request. Mutation and validation together guarantee that all accepted resources are consistent, complete, and conformant before entering the system.

#### Mutation Example

As an example of mutation during admission control, consider the creation of a **subnet**, which is a subresource of a **VPC** (network).

When a user submits a request with the following payload:

```json
{
  "labels": {
    "env": "production"
  },
  "annotations": {
    "description": "Human readable description"
  },
  "extensions": {},
  "spec": {
    "cidr": {
      "ipv4": "0.0.0.0/24",
      "ipv6": "::/64"
    },
    "zone": "a",
    "skuRef": "skus/seca.n1k"
  }
}
```

If the `routeTableRef` field is not specified in the request, the mutate admission controller will automatically populate it by using the `routeTableRef` associated with the parent network (VPC) to which the subnet belongs.  
This ensures that the subnet is correctly linked to a route table without requiring explicit user input, while still preserving the user's original intent.
