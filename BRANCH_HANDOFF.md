# Frontend and backend branch handoff

This repository contains the Footy AI frontend.

- **Frontend source:** this repository, branch `sinister/experimental`
- **Backend source:** `https://github.com/DevilSinister/football_summary.git`, branch `jugaad`

Agents working on the backend must pull the frontend changes from the
`sinister/experimental` branch of `footyai`. Agents working on the frontend must
pull the backend changes from the `jugaad` branch of `football_summary`.

Always fetch before integration and keep changes scoped to the repository and branch
that own them.
