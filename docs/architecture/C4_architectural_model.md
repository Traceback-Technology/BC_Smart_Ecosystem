# C4 architectural model

The C4 model breaks architecture into four levels:

1. *** System Context *** – what the system     interacts with

2. *** Container Diagram *** – major applications/services

3. *** Component Diagram *** – internal services/modules

4. *** Code Diagram *** – actual code structure


## level 1 - System contect diagram
System  internal and external interactions

                    ┌────────────────────────────┐
                    │          Students          │
                    │ Mobile App / Web Browser   │
                    └──────────────┬─────────────┘
                                   │
                                   ▼
                ┌─────────────────────────────────────┐
                │        Smart Campus Ecosystem       │
                │                                     │
                │  Campus platform + robotics + AI    │
                └───────┬───────────┬───────────┬─────┘
                        │           │           │
                        ▼           ▼           ▼

             ┌──────────────┐ ┌──────────────┐ ┌──────────────┐
             │ Campus Staff │ │ Food Vendors │ │ Security Ops │
             │ Admin Portal │ │ Order System │ │ Monitoring   │
             └──────────────┘ └──────────────┘ └──────────────┘

Interactors
- Students
- Campus adminisatation ( admin portal )
- Food vendors ( order systems )
- Robotics hardware
- Security teams ( monitoring )

---

## level 2 - Container diagram
Modular service component design 

                    ┌───────────────────────────┐
                    │      Web Platform         │
                    │ React / JS Frontend       │
                    └──────────────┬────────────┘
                                   │
                                   ▼
                    ┌───────────────────────────┐
                    │      Mobile Interface     │
                    │ Student App               │
                    └──────────────┬────────────┘
                                   │
                                   ▼
                    ┌───────────────────────────┐
                    │        Core Services      │
                    │ Students / Messaging      │
                    │ Events / QR Access        │
                    └───────┬─────────┬─────────┘
                            │         │
                            ▼         ▼

             ┌─────────────────────┐ ┌─────────────────────┐
             │   Analytics Engine  │ │  Robotics Platform  │
             │ Prediction + Data   │ │ Drone + Rover API   │
             └─────────┬───────────┘ └──────────┬──────────┘
                       │                        │
                       ▼                        ▼

                ┌─────────────────────────────────┐
                │        Campus Database          │
                │  Student Data + Activity Logs   │
                └─────────────────────────────────┘


## level 3 - Component diagram
Each component maps into a domain folder

e.g `Core/`

                 ┌─────────────────────┐
                 │     API Gateway     │
                 └──────────┬──────────┘
                            │
                            ▼

     ┌───────────────┬───────────────┬───────────────┐
     ▼               ▼               ▼
┌───────────┐  ┌────────────┐  ┌─────────────┐
│ Students  │  │ Messaging  │  │ Advertising │
│ Service   │  │ Service    │  │ Service     │
└─────┬─────┘  └─────┬──────┘  └──────┬──────┘
      │              │                │
      ▼              ▼                ▼

┌───────────────┐  ┌──────────────┐
│ QR Access     │  │ Activity     │
│ Service       │  │ Tracking     │
└───────────────┘  └──────────────┘


---

## level 4 - code diagram
actual code structure inside components

Controller
   │
   ▼
Service Layer
   │
   ▼
Repository Layer
   │
   ▼
Database

used for:
- separation of concerns
- testability
- clean architecture

