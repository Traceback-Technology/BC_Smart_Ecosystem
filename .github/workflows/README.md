# workflows

when someone opens a pull request:

lets visualise what happens:

Developer opens PR
        │
        ▼
GitHub triggers workflow
        │
        ▼
Start Ubuntu runner
        │
        ▼
Checkout repository
        │
        ▼
Run validation steps
        │
        ▼
Return result to GitHub
*** ( Checks passed / checks failed) ***

` GitHub spins up a temporary virtual machine running Ubuntu Linux to run the CI job. `

why we use substem pipelines, if not:
    - every change → rebuild entire project
    - wasted computation and builds

Instead we create *** monorepo selective CI ***

---
## when will it run

configured to run at different triggers:

| Pipeline      | Role                 |
| ------------- | -------------------- |
| core-ci       | campus service logic |
| platform-ci   | web + mobile         |
| robotics-ci   | drones + rover       |
| security-ci   | auth + monitoring    |
| analytics-ci  | AI modules           |
| infra-ci      | docker + deployment  |
| monorepo-ci   | global checks        |
| pr-validation | pull request rules   |
| lint-check    | code quality         |


