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

