# Data flow structures

## communication between subsystems
systems communicate through  APIs and event  messaging

_Data flow service chart_ :

Student places food order
        │
        ▼
Mobile App (platform)
        │
        ▼
Core Services
        │
        ▼
Delivery Coordination
        │
        ▼
Drone / Rover System
        │
        ▼
Delivery Status Updates
        │
        ▼
Analytics + Reporting

---


## QR system
This is used for attendance tracking, event participation and engagement metrics.

Campus Event
     │
     ▼
QR Code Generated
     │
     ▼
Student scans QR with app
     │
     ▼
core/QR-access service
     │
     ▼
Activity Tracking
     │
     ▼
Analytics System

### event tracking

Student orders food (mobile app)
        │
        ▼
Platform Layer
        │
        ▼
Core Services
        │
        ▼
Delivery Coordination
        │
        ▼
Drone System
        │
        ▼
Delivery status sent back
        │
        ▼
Student App Notification


---

## Security integration
The security subsystem integrates with core, platform and analytics -subsystems to name a few.

used for campus alerts, emergency notifications and anomaly detection

Security Cameras
        │
        ▼
security/
        │
        ▼
Core Monitoring Services
        │
        ▼
Alerts / Notifications
        │
        ▼
Student Platform

---

### Robotics integration
 
hardware independent systems will be isolated from the main application and its logic

Delivery Request
      │
      ▼
core/services
      │
      ▼
robotics/control-api
      │
      ├── drone-system
      │
      └── rover-system

#### Delivery

Student orders food (mobile app)
        │
        ▼
Platform Layer
        │
        ▼
Core Services
        │
        ▼
Delivery Coordination / control api
        │
        ▼
Drone System
        │
        ▼
Delivery status sent back
        │
        ▼
Student App Notification

---

## System architecture
Overview of BC ecosystem

               STUDENT USERS
                      │
                      ▼
           Web + Mobile Platform
                      │
                      ▼
               Core Services
     (communication, students, events)
                      │
        ┌─────────────┼─────────────┐
        ▼             ▼             ▼
   Analytics      Security       Robotics
 (prediction)     systems        systems
        │                           │
        ▼                           ▼
 Reporting                  Drones + Rovers
                      │
                      ▼
               Physical Campus