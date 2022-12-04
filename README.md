LTN: [Logistic Train Network](https://mods.factorio.com/mods/Optera/LogisticTrainNetwork)

[Cybersyn](https://mods.factorio.com/mod/cybersyn)

TCS: [Train Control Signals](https://mods.factorio.com/mod/Train_Control_Signals)

Are you an LTN/Cybersyn user but wishes to implement a separate centralised refuel station using TCS? This mod addresses that.

## What this mod DOES?
- Adds an additional stop to the end of the modded train schedule after dispatch (Cybersyn) / delivery pickup is complete (LTN). The stop name contains the TCS Refuel station virtual signal by default where TCS will redirect the train to the refuel stop if the fuel runs low.

## Additional instructions
- Station name and inactivity timeout can be configured through mod settings (under Map tab).
- LTN User: Make sure the setting - "Delivery completes at requester" is disabled.
- Cybersyn User: Make sure the "Depot Bypass Threshold" setting is set at 1.

## What this mod DOES NOT DO?
- DOES NOT change any refuel behaviours of train.
- DOES NOT interact with the depot function of TCS.