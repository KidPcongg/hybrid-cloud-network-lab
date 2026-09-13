## Fixing a duplicate IP assignment in the local LAN

![IP correction and successful ping](fix-duplicate-ip-veth-2026-09-10.png)

- Date: 2026-09-10
- Problem: both veth-gw and veth-host were assigned 172.16.10.1/24.
  Pinging that address inside the namespace reached the namespace itself.
- Fix: changed veth-host inside kidpcongg-host to 172.16.10.10/24.
  Kept veth-gw at 172.16.10.1/24.
- Verification: confirmed the new address and received 4/4 ping replies
  from 172.16.10.1 across the veth link.
- Separate finding: the namespace had no route to 8.8.8.8.
  Internet connectivity has not been configured or verified.
- Lesson: check interface addresses before treating a successful ping
  as proof of connectivity between two endpoints.

## AWS account baseline - 2026-09-12

![AWS Free plan initial credit](aws-free-plan-initial-credit-2026-09-12.png)

- Confirmed Free plan status.
- Remaining credit: USD 100.
- Remaining Free plan duration: 182 days.
- These values reflect the account state on the capture date.


## AWS budget setup — 2026-09-13

![AWS budget created](aws-budget-created-2026-09-13.png)

- Created hcn-lab-monthly-cost with a recurring monthly budget of USD 10.
- Configured actual-cost email alerts at 50% and 100%.
- No automated budget actions were attached.
- Credit exclusion is pending because charge-type filter data was unavailable.
- This budget sends alerts; it does not enforce a spending cap.
