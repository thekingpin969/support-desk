SupportDesk Pro — Product Requirements Document	**CONFIDENTIAL**

**SupportDesk Pro**

Product Requirements Document

|**Version**|1\.0.0|
| :- | :- |
|**Date**|February 2026|
|**Status**|**Production Ready**|
|**Platform**|Flutter (Mobile) + Node.js + SQL|


# **1. Executive Summary**
SupportDesk Pro is a multi-role customer support ticket management application built on Flutter (iOS & Android) with a Node.js REST API backend and a relational SQL database. The platform connects three distinct user roles — Client, Employee, and Admin — through a structured, accountability-driven workflow that ensures every support ticket receives a timely, quality-verified response.

The system automates ticket routing to the least-loaded available employee, enforces SLA-based response time intervals, provides an admin verification layer before responses reach clients, and escalates SLA breaches with notifications and reassignment options. Image attachments are handled via ImgBB CDN.

|<p>**Core Value Proposition**</p><p>Clients raise issues and receive verified responses. Employees manage assigned tickets within SLA windows. Admins oversee quality, enforce accountability, and resolve escalations — all through role-specific mobile dashboards.</p>|
| :- |

## **1.1 Key Objectives**
- Provide a frictionless, multi-role mobile experience for client support
- Enforce SLA compliance with automated escalation and admin override
- Guarantee response quality through mandatory admin verification before client delivery
- Enable intelligent, load-balanced automatic ticket assignment to employees
- Deliver real-time notifications across all roles via push and in-app alerts

## **1.2 Success Metrics**

|**Metric**|**Target**|**Measurement**|
| :- | :- | :- |
|First Response SLA Compliance|>= 95%|Monthly report|
|Ticket Resolution Time (Avg)|< 24 hours|Dashboard KPI|
|Admin Verification Turnaround|< 2 hours|Dashboard KPI|
|App Crash Rate|< 0.1%|Firebase Crashlytics|
|API Uptime|>= 99.5%|Uptime monitoring|
|Client Satisfaction Score|>= 4.2 / 5|Post-resolution survey|


# **2. Scope & Boundaries**
## **2.1 In Scope**
- Flutter mobile application for Android and iOS (single codebase)
- Three separate authenticated user roles: Client, Employee, Admin
- Ticket lifecycle management: creation, assignment, response, verification, closure
- Automated load-balanced ticket assignment engine
- SLA timer with breach detection, notifications, and escalation
- Admin verification workflow before any response is sent to clients
- Image upload support via ImgBB API
- Push notifications and in-app notification center
- Three role-specific dashboards with relevant KPIs
- JWT-based authentication with email/password
- RESTful Node.js/Express backend with SQL database (PostgreSQL recommended)
- In-app ticket reassignment by admin

## **2.2 Out of Scope (v1.0)**
- Web portal / browser-based interface
- Live chat / real-time chat messaging (separate from ticket responses)
- Third-party CRM integrations (Salesforce, Zendesk, etc.)
- Multi-language / i18n support
- SLA auto-configuration by client tier or contract
- Video or voice attachments
- Public knowledge base or self-service FAQ


# **3. User Roles & Personas**
## **3.1 Client**

|<p>**Client**</p><p>Any registered end-user who needs support. Clients create tickets, track status, and receive final verified responses from the support team.</p>|
| :- |

### **Client Capabilities**
- Register and log in with email and password
- Create support tickets with title, description, category, and priority
- Attach one or more images to a ticket (uploaded via ImgBB)
- View all their own tickets with current status and timeline
- Receive push notifications when ticket status changes
- Receive admin-verified responses from the support team
- Rate closed tickets (1–5 stars with optional comment)
- Re-open a closed ticket if the issue persists (once per ticket)

## **3.2 Employee**

|<p>**Employee**</p><p>Support staff who handle assigned tickets. Each employee has a capacity, receives tickets automatically, and must respond within the SLA window before forwarding to admin for verification.</p>|
| :- |

### **Employee Capabilities**
- Log in with email and password (account created by Admin)
- View personal dashboard: assigned tickets by status, open count, SLA countdown timers
- View full ticket detail including client-submitted images
- Draft a response to an assigned ticket
- Attach images to the response via ImgBB
- Submit the drafted response to admin for verification
- Receive push notifications for new ticket assignments
- Receive escalation notifications when approaching or breaching SLA
- Cannot directly send responses to clients

## **3.3 Admin**

|<p>**Admin**</p><p>The system operator responsible for quality assurance, employee management, SLA enforcement, and final response delivery to clients. The Admin has full system visibility.</p>|
| :- |

### **Admin Capabilities**
- Log in with email and password (first admin seeded at deployment)
- View global dashboard: all tickets across all statuses, all employees
- Create and manage employee accounts (name, email, capacity, department)
- View per-employee workload: open and closed ticket counts, SLA compliance rate
- Receive employee-forwarded ticket responses for verification
- Approve a response: delivers it to the client and closes the ticket
- Reject a response with feedback: sends it back to the employee for revision
- Force-notify an employee who is approaching or has breached SLA
- Reassign a ticket from one employee to another
- Configure system-wide SLA intervals per ticket priority
- Configure ticket categories
- View system-wide analytics: volume, SLA compliance, avg resolution time


# **4. Functional Requirements**
## **4.1 Authentication & Authorization**
All three roles use separate authentication flows on the same backend. A role field in the JWT payload determines routing and access control. Email/password authentication is used for all roles.

|**Feature**|**Client**|**Employee**|**Admin**|
| :- | :- | :- | :- |
|Self-registration|Yes|No (Admin creates)|No (Seeded)|
|Email/password login|Yes|Yes|Yes|
|Password reset via email|Yes|Yes|Yes|
|JWT access token (15 min)|Yes|Yes|Yes|
|JWT refresh token (30 days)|Yes|Yes|Yes|
|Account deactivation|Self|Admin only|N/A|

## **4.2 Ticket Management**
### **4.2.1 Ticket Creation (Client)**
1. Client taps 'New Ticket' on their dashboard
1. Fills in: Title (required), Description (required), Category (dropdown), Priority (Low / Medium / High / Critical)
1. Optionally attaches up to 5 images (uploaded to ImgBB, URL stored in DB)
1. Submits ticket — system generates unique ticket ID (TKT-YYYYMMDD-XXXX)
1. Status set to OPEN, SLA timer starts based on priority
1. Assignment engine runs immediately (see Section 4.3)
1. Client and assigned employee both receive push notifications

### **4.2.2 Ticket Status Lifecycle**

|**Status**|**Description**|**Who Triggers**|
| :- | :- | :- |
|OPEN|Ticket created, awaiting or assigned to employee|System (on creation)|
|ASSIGNED|Ticket routed to an employee, SLA timer active|System (assignment engine)|
|IN\_PROGRESS|Employee is actively drafting a response|Employee (first edit)|
|PENDING\_REVIEW|Employee has forwarded response to admin|Employee (submit action)|
|REVISION\_REQUESTED|Admin rejected response, back to employee|Admin (reject action)|
|RESOLVED|Admin approved response, sent to client|Admin (approve action)|
|CLOSED|Client rated OR 7 days after RESOLVED with no rating|Client or System (auto)|
|REOPENED|Client reopened a CLOSED ticket once|Client (reopen action)|
|ESCALATED|SLA breached, flagged for admin attention|System (SLA engine)|
|REASSIGNED|Admin moved ticket to a different employee|Admin (reassign action)|

### **4.2.3 Ticket Detail View (All Roles)**
- Ticket ID, title, category, priority badge, current status badge
- Client info (name, email) — visible to Employee and Admin only
- Creation timestamp, SLA deadline, time remaining (live countdown)
- Full description text with embedded image thumbnails
- Audit timeline: status change history with timestamps and actor
- Response thread: employee draft(s) and admin feedback
- For Admin: employee assignment info and workload summary

## **4.3 Ticket Assignment Engine**
When a new ticket is created (or reassigned), the backend runs the automatic assignment algorithm:

1. Query all active (non-deactivated) employees
1. Filter to employees whose current open ticket count is below their configured capacity limit (default: 10 tickets)
1. Among eligible employees, select the one with the fewest open tickets (ties broken by least recently assigned)
1. If no eligible employee exists (all at capacity), the ticket remains in OPEN status and the Admin is notified
1. Assignment is atomic — race conditions prevented by database-level row locking

|<p>**Capacity Configuration**</p><p>Each employee has a configurable max\_capacity field (default 10). Admin can adjust per employee. When an employee is deactivated, all their OPEN/ASSIGNED tickets are returned to the pool and re-assigned.</p>|
| :- |

## **4.4 SLA Engine**
### **4.4.1 SLA Intervals (Admin Configurable)**

|**Priority**|**Default Response Deadline**|**Warning Threshold**|
| :- | :- | :- |
|Critical|2 hours|1 hour remaining|
|High|8 hours|2 hours remaining|
|Medium|24 hours|4 hours remaining|
|Low|72 hours|12 hours remaining|

SLA timer measures time from ticket assignment to employee forwarding the response to admin. Admin verification time is excluded from the SLA window.

### **4.4.2 SLA Breach Handling**
1. At warning threshold: employee receives a push notification warning
1. At SLA deadline: ticket status changes to ESCALATED, admin receives notification
1. Admin options on ESCALATED ticket:
   - Force-notify employee (sends urgent push + in-app notification with escalation flag)
   - Reassign the ticket to a different employee (SLA timer resets with a grace period = 50% of original SLA)
1. Escalation history is recorded in the audit timeline

## **4.5 Response Workflow**
### **4.5.1 Employee Response Submission**
1. Employee opens an ASSIGNED or IN\_PROGRESS ticket
1. Drafts a response in a rich text field (plain text + line breaks)
1. Optionally attaches images via ImgBB
1. Taps 'Forward to Admin' — status changes to PENDING\_REVIEW
1. Employee can no longer edit the response once forwarded
1. Admin receives push notification: 'New response pending review'

### **4.5.2 Admin Verification**
1. Admin opens the PENDING\_REVIEW ticket
1. Reviews the full ticket context and employee's response
1. Option A — Approve: response is sent to the client; ticket status set to RESOLVED; client receives push notification with the response content
1. Option B — Reject: admin provides rejection reason/feedback; status reverts to REVISION\_REQUESTED; employee receives notification with the feedback
1. Employee can revise and resubmit; the cycle repeats until approved
1. All approve/reject actions are logged in the audit trail

## **4.6 Image Handling**
All image uploads (client attachments and employee response attachments) are processed via the ImgBB API using a server-side proxy to protect the API key.

- Supported formats: JPEG, PNG, WebP, GIF (static)
- Maximum file size per image: 10 MB
- Maximum images per ticket (client): 5
- Maximum images per employee response: 5
- Flow: Client/Employee selects image -> Flutter compresses to max 1200px wide -> Base64 encoded -> Sent to backend proxy endpoint -> Backend calls ImgBB API -> ImgBB returns URL -> URL stored in DB against the ticket/response
- Images are displayed as tappable thumbnails opening a full-screen viewer with zoom


# **5. Dashboard Specifications**
## **5.1 Client Dashboard**

|**Widget / Section**|**Content**|**Behavior**|
| :- | :- | :- |
|Summary Cards|Total tickets, Open, Resolved, Closed|Tap to filter ticket list|
|Active Tickets List|Open + In-Progress + Escalated tickets|Sorted by SLA deadline (soonest first)|
|Ticket Card|ID, title, status badge, priority badge, SLA countdown|Tap to open detail|
|Resolved Tickets List|Resolved tickets pending rating|Rating prompt shown|
|Notification Bell|Unread notification count badge|Tap to open notification center|
|New Ticket FAB|Floating action button|Opens ticket creation form|

## **5.2 Employee Dashboard**

|**Widget / Section**|**Content**|**Behavior**|
| :- | :- | :- |
|KPI Strip|Open tickets count, SLA compliance %, avg response time|Read-only KPIs|
|SLA Alert Banner|Shows count of tickets in warning or escalated state|Tap to filter to those tickets|
|My Tickets — Active|ASSIGNED / IN\_PROGRESS / REVISION\_REQUESTED tickets|Sorted by SLA deadline ascending|
|Ticket Card|ID, title, priority, SLA countdown timer (live), status|Tap to open and respond|
|My Tickets — Closed|RESOLVED / CLOSED tickets (paginated)|Historical view|
|Notification Center|All notifications for this employee|Mark as read individually or all|

## **5.3 Admin Dashboard**

|**Widget / Section**|**Content**|**Behavior**|
| :- | :- | :- |
|Global KPI Cards|Total tickets today, SLA breach count, Pending Review count, Avg resolution time|Tap KPI to drill down|
|Pending Review Queue|All PENDING\_REVIEW tickets sorted by submission time|Primary action area|
|Escalated Tickets|All ESCALATED tickets with employee name and breach duration|Force-notify or Reassign CTAs|
|All Tickets Table|Filterable by status, priority, category, date range, employee|Full search and export|
|Employee Roster|Each employee: name, open count, capacity bar, SLA compliance %, active/inactive toggle|Tap to see employee detail|
|Employee Detail|Employee's full ticket list (active + closed), response time chart|Reassign tickets from here|
|SLA Config Panel|Edit SLA intervals per priority tier|Settings section|
|Category Manager|Add / edit / archive ticket categories|Settings section|


# **6. Notification System**
## **6.1 Notification Events**

|**Event**|**Recipient(s)**|**Channel**|
| :- | :- | :- |
|New ticket created and assigned|Assigned Employee|Push + In-app|
|Ticket reassigned to me|New Employee|Push + In-app|
|Ticket reassigned away from me|Previous Employee|In-app|
|SLA warning threshold reached|Assigned Employee|Push + In-app|
|SLA breached (ticket escalated)|Assigned Employee + Admin|Push + In-app|
|Admin force-notified me on escalated ticket|Employee|Push + In-app (urgent)|
|Employee submitted response for review|Admin|Push + In-app|
|Admin approved my response|Employee|Push + In-app|
|Admin rejected my response|Employee|Push + In-app (with feedback)|
|Support team responded to your ticket|Client|Push + In-app|
|Ticket resolved|Client|Push + In-app|
|Ticket reopened by client|Admin + Employee|Push + In-app|
|No employee available (all at capacity)|Admin|Push + In-app|

## **6.2 Notification Infrastructure**
- Push notifications delivered via Firebase Cloud Messaging (FCM)
- Device tokens registered on login and refreshed on token rotation
- In-app notification center stores last 90 days of notifications per user
- Notifications are marked as read individually or via 'Mark all as read'
- Backend scheduled job (cron) runs every 60 seconds to check SLA thresholds and fire alerts


# **7. Data Model**
## **7.1 Entity Relationship Overview**
The core entities and their relationships are described below. PostgreSQL is the recommended database engine.

### **users**

|**Column**|**Type**|**Notes**|
| :- | :- | :- |
|id|UUID PK|Primary key|
|email|VARCHAR(255) UNIQUE NOT NULL|Login identifier|
|password\_hash|VARCHAR(255) NOT NULL|bcrypt hashed|
|role|ENUM(client, employee, admin) NOT NULL|Role-based access|
|full\_name|VARCHAR(100) NOT NULL|Display name|
|phone|VARCHAR(20)|Optional contact|
|is\_active|BOOLEAN DEFAULT true|Soft delete flag|
|fcm\_token|TEXT|Firebase push token|
|created\_at|TIMESTAMPTZ DEFAULT now()||
|updated\_at|TIMESTAMPTZ DEFAULT now()||

### **employee\_profiles**

|**Column**|**Type**|**Notes**|
| :- | :- | :- |
|id|UUID PK||
|user\_id|UUID FK -> users(id)|One-to-one with users|
|department|VARCHAR(100)|Employee department|
|max\_capacity|INTEGER DEFAULT 10|Max concurrent open tickets|
|open\_ticket\_count|INTEGER DEFAULT 0|Cached counter (updated on assign/close)|
|last\_assigned\_at|TIMESTAMPTZ|Tiebreaker for assignment engine|

### **tickets**

|**Column**|**Type**|**Notes**|
| :- | :- | :- |
|id|UUID PK||
|ticket\_number|VARCHAR(20) UNIQUE|TKT-YYYYMMDD-XXXX human readable|
|client\_id|UUID FK -> users(id)|Ticket creator|
|assigned\_employee\_id|UUID FK -> users(id) NULLABLE|Current assignee|
|category\_id|UUID FK -> categories(id)||
|priority|ENUM(low, medium, high, critical)||
|status|ENUM(open, assigned, in\_progress, pending\_review, revision\_requested, resolved, closed, reopened, escalated, reassigned)||
|title|VARCHAR(255) NOT NULL||
|description|TEXT NOT NULL||
|sla\_deadline|TIMESTAMPTZ|Calculated on assignment|
|sla\_warning\_sent\_at|TIMESTAMPTZ NULLABLE|Prevents duplicate warnings|
|escalated\_at|TIMESTAMPTZ NULLABLE|When breach occurred|
|resolved\_at|TIMESTAMPTZ NULLABLE|When admin approved response|
|closed\_at|TIMESTAMPTZ NULLABLE||
|rating|SMALLINT NULLABLE|1–5 from client|
|rating\_comment|TEXT NULLABLE||
|reopen\_count|SMALLINT DEFAULT 0|Max 1|
|created\_at|TIMESTAMPTZ DEFAULT now()||
|updated\_at|TIMESTAMPTZ DEFAULT now()||

### **ticket\_images**

|**Column**|**Type**|**Notes**|
| :- | :- | :- |
|id|UUID PK||
|ticket\_id|UUID FK -> tickets(id)||
|imgbb\_url|TEXT NOT NULL|Full ImgBB image URL|
|imgbb\_delete\_url|TEXT|For future deletion capability|
|uploaded\_by|UUID FK -> users(id)|Client or Employee|
|context|ENUM(ticket, response)|Ticket attachment vs response attachment|
|created\_at|TIMESTAMPTZ DEFAULT now()||

### **ticket\_responses**

|**Column**|**Type**|**Notes**|
| :- | :- | :- |
|id|UUID PK||
|ticket\_id|UUID FK -> tickets(id)||
|employee\_id|UUID FK -> users(id)|Author of response|
|response\_text|TEXT NOT NULL||
|status|ENUM(draft, pending\_review, approved, rejected)||
|admin\_feedback|TEXT NULLABLE|Rejection reason from admin|
|reviewed\_by|UUID FK -> users(id) NULLABLE|Admin who actioned|
|submitted\_at|TIMESTAMPTZ NULLABLE|When forwarded to admin|
|reviewed\_at|TIMESTAMPTZ NULLABLE||
|created\_at|TIMESTAMPTZ DEFAULT now()||

### **Other Tables**

|**Table**|**Purpose**|**Key Fields**|
| :- | :- | :- |
|categories|Ticket category list (managed by admin)|id, name, is\_active|
|sla\_configs|Priority-to-deadline mapping|priority, response\_hours, warning\_hours|
|ticket\_audit\_log|Immutable status change history|ticket\_id, from\_status, to\_status, actor\_id, changed\_at, note|
|notifications|In-app notification store|user\_id, type, message, payload\_json, is\_read, created\_at|
|refresh\_tokens|JWT refresh token store|id, user\_id, token\_hash, expires\_at, is\_revoked|


# **8. API Specification**
## **8.1 Base URL & Conventions**
- Base URL: https://api.supportdesk.app/v1
- All requests and responses use JSON (Content-Type: application/json)
- Authentication: Bearer token in Authorization header
- Error responses follow: { "error": { "code": "ERR\_CODE", "message": "Human readable" } }
- Paginated endpoints accept: ?page=1&limit=20
- Timestamps in ISO 8601 UTC format

## **8.2 Auth Endpoints**

|**Method**|**Endpoint**|**Auth**|**Description**|
| :- | :- | :- | :- |
|POST|/auth/register|Public|Client self-registration|
|POST|/auth/login|Public|Login for all roles, returns access + refresh tokens|
|POST|/auth/refresh|Refresh Token|Issue new access token|
|POST|/auth/logout|Bearer|Revoke refresh token|
|POST|/auth/forgot-password|Public|Send reset email|
|POST|/auth/reset-password|Reset Token|Set new password|

## **8.3 Ticket Endpoints**

|**Method**|**Endpoint**|**Auth**|**Description**|
| :- | :- | :- | :- |
|POST|/tickets|Client|Create new ticket|
|GET|/tickets|All|List tickets (scoped by role)|
|GET|/tickets/:id|All|Get ticket detail|
|PATCH|/tickets/:id/status|System/Admin|Internal status update|
|POST|/tickets/:id/images|Client/Employee|Upload image via ImgBB proxy|
|POST|/tickets/:id/responses|Employee|Create/update draft response|
|POST|/tickets/:id/responses/:rid/submit|Employee|Forward response to admin|
|POST|/tickets/:id/responses/:rid/approve|Admin|Approve and send to client|
|POST|/tickets/:id/responses/:rid/reject|Admin|Reject with feedback|
|POST|/tickets/:id/reassign|Admin|Reassign to different employee|
|POST|/tickets/:id/escalate-notify|Admin|Force-notify employee on escalated ticket|
|POST|/tickets/:id/reopen|Client|Reopen a closed ticket (once)|
|POST|/tickets/:id/rate|Client|Submit rating for resolved ticket|
|GET|/tickets/:id/audit|Employee/Admin|Get audit trail|

## **8.4 Admin & Employee Endpoints**

|**Method**|**Endpoint**|**Auth**|**Description**|
| :- | :- | :- | :- |
|GET|/admin/employees|Admin|List all employees with workload|
|POST|/admin/employees|Admin|Create employee account|
|PATCH|/admin/employees/:id|Admin|Update employee (capacity, dept, active)|
|GET|/admin/employees/:id/tickets|Admin|Employee's ticket list|
|GET|/admin/analytics|Admin|Global KPIs|
|GET|/admin/sla-config|Admin|Get SLA settings|
|PUT|/admin/sla-config|Admin|Update SLA settings|
|GET|/admin/categories|Admin|List categories|
|POST|/admin/categories|Admin|Create category|
|PATCH|/admin/categories/:id|Admin|Edit / archive category|
|GET|/employees/me/dashboard|Employee|Personal dashboard data|
|GET|/notifications|All|Paginated notification list|
|PATCH|/notifications/read-all|All|Mark all notifications as read|


# **9. Technology Stack**
## **9.1 Mobile — Flutter**

|**Layer**|**Package / Tool**|**Purpose**|
| :- | :- | :- |
|State Management|flutter\_bloc / Cubit|Predictable state, easy testing|
|Navigation|go\_router|Declarative routing with deep links|
|HTTP Client|dio|REST calls, interceptors, token refresh|
|Local Storage|flutter\_secure\_storage|JWT token storage|
|Image Picker|image\_picker|Camera and gallery access|
|Image Compression|flutter\_image\_compress|Reduce payload before upload|
|Push Notifications|firebase\_messaging|FCM integration|
|Local Notifications|flutter\_local\_notifications|Foreground notification display|
|Date/Time|intl|Formatting and SLA countdowns|
|Form Validation|formz|Typed form field validation|
|Dependency Injection|get\_it|Service locator|
|Analytics / Crash|firebase\_analytics + firebase\_crashlytics|Production monitoring|
|Environment Config|flutter\_dotenv|Environment-specific configs|

## **9.2 Backend — Node.js**

|**Layer**|**Package / Tool**|**Purpose**|
| :- | :- | :- |
|Runtime|Node.js 20 LTS||
|Framework|Express.js 5|REST API framework|
|Language|TypeScript 5|Type safety|
|ORM|Prisma 5|Type-safe DB queries, migrations|
|Database|PostgreSQL 16|Primary data store|
|Auth|jsonwebtoken + bcryptjs|JWT signing and password hashing|
|Validation|zod|Request schema validation|
|File Upload Proxy|axios|Server-side ImgBB calls|
|Push Notifications|firebase-admin|FCM server SDK|
|Email|nodemailer + SendGrid|Password reset emails|
|Scheduled Jobs|node-cron|SLA monitoring (every 60s)|
|Rate Limiting|express-rate-limit|API abuse prevention|
|Logging|winston + morgan|Structured logging|
|Testing|jest + supertest|Unit and integration tests|
|Process Manager|PM2|Production process management|
|Containerization|Docker + docker-compose|Deployment|

## **9.3 Infrastructure**

|**Component**|**Recommended Service**|**Notes**|
| :- | :- | :- |
|API Server|AWS EC2 / DigitalOcean Droplet|Dockerized Node.js|
|Database|AWS RDS PostgreSQL / Supabase|Managed, automated backups|
|Image CDN|ImgBB API|Simple email/password API key auth|
|Push Notifications|Firebase Cloud Messaging (FCM)|Free tier sufficient for v1|
|Email Service|SendGrid|Transactional email, 100/day free|
|Reverse Proxy|Nginx|SSL termination, rate limiting|
|SSL|Let's Encrypt|Auto-renewing certificates|
|CI/CD|GitHub Actions|Automated test + deploy pipeline|
|Monitoring|UptimeRobot + Firebase Crashlytics|Uptime + crash reporting|


# **10. Security Requirements**
## **10.1 Authentication Security**
- Passwords hashed with bcrypt (cost factor 12)
- JWT access tokens expire in 15 minutes; refresh tokens expire in 30 days
- Refresh tokens stored hashed in DB; single-use rotation on each refresh
- Account lockout after 5 failed login attempts (15-minute lockout)
- Password reset tokens are single-use, expire in 1 hour, hashed in DB

## **10.2 API Security**
- All endpoints require valid JWT except /auth/register, /auth/login, /auth/forgot-password, /auth/reset-password
- Role-based middleware validates role claim in JWT on every protected route
- Rate limiting: 100 req/15 min per IP globally; 10 req/15 min on auth endpoints
- Input validation on all request bodies using zod schemas
- SQL injection prevention via Prisma parameterized queries (no raw string interpolation)
- ImgBB API key stored server-side only; clients never receive the key
- CORS configured to allow only production app domains
- HTTPS enforced; HTTP redirects to HTTPS via Nginx

## **10.3 Data Privacy**
- Client email addresses are only visible to Employees and Admins on ticket detail — not in list views
- Employees can only view tickets assigned to them; cannot view other employees' tickets
- Clients cannot see other clients' ticket data
- Admin audit logs are immutable; no delete/edit operations permitted
- Soft-delete for user accounts (is\_active = false) preserves ticket history integrity

# **11. Non-Functional Requirements**

|**Category**|**Requirement**|**Target**|
| :- | :- | :- |
|Performance|API p95 response time (non-file endpoints)|< 300ms|
|Performance|API p99 response time|< 800ms|
|Performance|Flutter app cold start time|< 3 seconds|
|Performance|Flutter UI frame rate (scrolling/animations)|>= 60 fps|
|Scalability|Concurrent API users (v1)|500 concurrent|
|Reliability|API uptime SLA|>= 99.5% monthly|
|Reliability|SLA cron job execution accuracy|Within ±60 seconds|
|Storage|Image stored via ImgBB (no local storage)|Unlimited (ImgBB limits)|
|Compatibility|iOS support|>= iOS 14|
|Compatibility|Android support|>= Android 8.0 (API 26)|
|Accessibility|Text scaling support|Up to 200% system text size|
|Offline|Graceful degradation (no crash on no network)|Show offline banner|
|Localization|v1 language|English only|


# **12. Edge Cases & Gap Analysis**
## **12.1 Identified Gaps & Resolutions**

|**Gap / Scenario**|**Resolution**|
| :- | :- |
|All employees at full capacity when a ticket is created|Ticket stays OPEN; Admin receives immediate notification. Admin can raise capacity or create a new employee account. Ticket is shown in a separate 'Unassigned' queue on Admin dashboard.|
|Employee account deactivated mid-ticket|On deactivation, all OPEN/ASSIGNED tickets of that employee are immediately returned to unassigned pool and re-processed by the assignment engine.|
|Client submits duplicate/identical tickets|Backend checks for open tickets with same title + client within 10 minutes and returns a warning (not hard block). Client can confirm or cancel.|
|ImgBB upload failure|Backend returns error; Flutter shows retry option. Ticket can be submitted without images. Failed uploads are logged.|
|Admin rejects a response multiple times|No hard limit on rejection cycles, but each rejection is logged. If same ticket has 3+ rejections, a flag appears on Admin dashboard suggesting reassignment.|
|Client closes app during ticket creation|Form state is preserved in Flutter local state for the session. Not persisted to disk (no sensitive data stored locally).|
|SLA cron job downtime / missed checks|On cron restart, it performs a catch-up query for all tickets where sla\_deadline < now() and status not in (resolved, closed) and processes them immediately.|
|Ticket reopened and no employees available|Same as new ticket: stays OPEN, Admin notified.|
|Employee leaves mid-response draft|Draft is stored in ticket\_responses with status=draft. Employee can resume on next visit.|
|Two admins approve/reject same response simultaneously|DB-level optimistic locking on ticket\_responses. Second admin receives 'already actioned' error.|


# **13. Development Phases & Timeline**

|**Phase**|**Deliverables**|**Duration**|
| :- | :- | :- |
|Phase 1: Foundation|DB schema + migrations, Auth API (all 3 roles), Basic Flutter app shell with routing, Login/Register screens for all 3 roles|2 weeks|
|Phase 2: Core Ticket Workflow|Ticket CRUD API, Client ticket creation flow, Assignment engine, Employee ticket list + detail + response submission, Basic status lifecycle|3 weeks|
|Phase 3: Admin & Verification|Admin dashboard data APIs, Employee management API, Admin response verification workflow, Rejection cycle, Admin reassignment|2 weeks|
|Phase 4: SLA & Notifications|SLA engine + cron job, FCM push notification integration, In-app notification center, SLA warning + escalation flow, Force-notify + reassign by admin|2 weeks|
|Phase 5: Dashboards & Polish|Full dashboard widgets for all 3 roles, Analytics endpoints, Rating system, Ticket reopening, Image viewer, Form validation, Error states|2 weeks|
|Phase 6: QA & Security Hardening|Penetration testing, Load testing (k6), Security audit, Bug fixes, App store submission prep|1 week|
|Phase 7: Deployment|Production infrastructure setup, CI/CD pipeline, Monitoring configuration, Soft launch|1 week|

|<p>**Total Estimated Duration**</p><p>13 weeks from project kickoff to production deployment. Timeline assumes a team of 2 Flutter developers, 1 Node.js backend developer, and 1 QA engineer with part-time involvement from a DevOps resource.</p>|
| :- |


# **14. Open Questions & Decision Log**

|**#**|**Question**|**Options**|**Decision / Owner**|
| :- | :- | :- | :- |
|1|Should employee accounts support self-registration or admin-only creation?|A: Admin-only  B: Self-reg with approval|Admin-only for v1 (tighter control). Self-reg workflow in v2.|
|2|Should the client rating be mandatory before ticket closure?|A: Mandatory  B: Optional  C: Auto-close after 7 days|Optional + auto-close after 7 days (prevents friction).|
|3|Should attachment deletion be supported post-submission?|A: No deletion  B: Admin-only deletion|No deletion in v1 (audit integrity). Admin-only in v2.|
|4|Multi-language support timeline?|A: v1  B: v2|v2. English-only for v1.|
|5|Should clients be able to add more images after ticket submission?|A: Yes (up to limit)  B: No|No — prevents scope creep on submitted tickets. Comments/additional info via text only.|
|6|Database: PostgreSQL vs MySQL?|A: PostgreSQL  B: MySQL|PostgreSQL — better JSON support, row-level locking, and Prisma compatibility.|

# **15. Release Acceptance Criteria**
The following criteria must all pass before production release:

1. All 3 authentication flows (Client, Employee, Admin) work end-to-end on both iOS and Android
1. Client can create a ticket with images and view its status in real time
1. Assignment engine correctly assigns to least-loaded employee in automated tests
1. Employee receives push notification within 60 seconds of ticket assignment
1. SLA warning notification fires at the configured threshold (±2 minutes tolerance)
1. SLA breach escalation fires and Admin receives notification within 2 minutes of breach
1. Admin can approve a response and client receives push notification within 60 seconds
1. Admin can reject a response and employee receives feedback notification
1. Admin can force-notify an employee on an escalated ticket
1. Admin can reassign a ticket and new employee receives notification
1. All API endpoints return appropriate 401/403 for unauthorized access attempts
1. Load test: API handles 500 concurrent users with p95 < 300ms on core endpoints
1. Zero critical or high-severity security vulnerabilities in OWASP Top 10 audit
1. Flutter app achieves >= 60fps on a mid-range Android device (Pixel 6a or equivalent)
1. App crash rate < 0.1% in 48-hour beta period

# **Appendix A: Ticket Number Format**
Ticket numbers follow the format: TKT-YYYYMMDD-XXXX where XXXX is a zero-padded sequential counter per day. Example: TKT-20260228-0043. The counter resets to 0001 each calendar day (UTC). This format provides human-readable, chronologically sortable, and customer-friendly ticket references.

# **Appendix B: ImgBB Integration**
ImgBB is used as the image hosting provider. The backend holds the API key obtained from imgbb.com (email/password account). All image uploads from the Flutter app are proxied through the backend:

1. Flutter compresses image and sends multipart/form-data to POST /v1/images/upload
1. Backend receives file, constructs ImgBB API request with the server-held API key
1. Backend calls https://api.imgbb.com/1/upload with the image data
1. ImgBB returns JSON with display\_url, url, and delete\_url
1. Backend stores display\_url and delete\_url in ticket\_images table and returns the URL to Flutter

Note: ImgBB free plan stores images indefinitely. Images deleted from ImgBB would break historical ticket records; therefore no deletion is performed in v1.

# **Appendix C: Environment Configuration**

|**Variable**|**Description**|**Required**|
| :- | :- | :- |
|DATABASE\_URL|PostgreSQL connection string|Yes|
|JWT\_ACCESS\_SECRET|Secret for signing access tokens (min 32 chars)|Yes|
|JWT\_REFRESH\_SECRET|Secret for signing refresh tokens (min 32 chars)|Yes|
|IMGBB\_API\_KEY|ImgBB API key|Yes|
|FIREBASE\_CREDENTIALS\_JSON|Firebase Admin SDK service account JSON|Yes|
|SENDGRID\_API\_KEY|SendGrid email API key|Yes|
|FROM\_EMAIL|Sender email address for transactional emails|Yes|
|FRONTEND\_URL|Flutter app deep link base URL (for email links)|Yes|
|PORT|API server port (default: 3000)|No|
|NODE\_ENV|development / production|Yes|
|CORS\_ORIGINS|Comma-separated allowed CORS origins|Yes|

End of Document — SupportDesk Pro PRD v1.0

Prepared February 2026 | All rights reserved
Version 1.0 | February 2026	Page 
