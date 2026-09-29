# BC Smart Lifestyle

## Overview
BC Smart Lifestyle is a centralized, multi-module application designed to modernize the student and visitor experience at Belgium Campus iTversity. The system integrates advanced navigation and automated services to address operational inefficiencies and enhance campus safety.

### Core Modules
*   **BC Ways (2D Navigation):** A digital navigation system optimized for pedestrian movement, featuring shortest-path generation using Dijkstra’s Algorithm and real-time GPS tracking.
*   **BC Eats (Tuckshop & Delivery):** A digitized dining experience featuring mobile pre-ordering, cashless payments, and an autonomous drone delivery system.

---

## 🛠 Tech Stack
*   **Frontend:** [Flutter](https://flutter.dev/) (Mobile & Web)
*   **Backend:** [Node.js](https://nodejs.org/) with [Express](https://expressjs.com/) & [TypeScript](https://www.typescriptlang.org/)
*   **Real-time Communication:** [Socket.IO](https://socket.io/)
*   **Database:** [MongoDB](https://www.mongodb.com/) (GeoJSON & 2dsphere indexes)
*   **Hardware/IoT:** C++ (Pixhawk 4 / ArduPilot / YOLO)

---

## 📂 Repository Structure
```text
bc-smart-lifestyle/
├── apps/
│   ├── mobile_app/             # Flutter (Dart) - Main App & Visitor Web Dashboard
│   ├── server/                 # Node.js (TS) - API, Pathfinding, & Socket Server
│   └── hardware/               # C++ - Drone Firmware & Parking Camera Logic
├── docs/                       # Project Documentation & Diagrams
├── .github/                    # CI/CD Workflows
└── docker-compose.yml          # Local Environment Setup (MongoDB)
```

---

## 🚀 Getting Started

### Prerequisites
*   [Flutter SDK](https://docs.flutter.dev/get-started/install)
*   [Node.js](https://nodejs.org/) (v18+)
*   [Docker](https://www.docker.com/) (for local database)

### Setup
1.  **Clone the repository:**
    ```bash
    git clone <repo-url>
    cd bc-smart-lifestyle
    ```

2.  **Start Database:**
    ```bash
    docker-compose up -d
    ```

3.  **Run Backend:**
    ```bash
    cd apps/server
    npm install
    npm run dev
    ```

4.  **Run Mobile App:**
    ```bash
    cd apps/mobile_app
    flutter pub get
    flutter run
    ```

---

## 👥 Team (Group 8)

| Anele Nkayi | Backend / Frontend |
| Mufunwa Muofhe | Backend |
| Dzanga Madi |Frontend |
| Puleng Ramorapeli | Frontend |
| Arnold Mabope |Backend / Hardware |
| Thabang Molise |Backend / Hardware |
| Tetelo Phahladira |Frontend / Hardware |
| Jimmy Junior Baloyi |Frontend |

---

## 📝 License
This project is developed for educational purposes at Belgium Campus iTversity.
