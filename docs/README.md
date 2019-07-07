
Serenity is developing Smart Energy Broker HEPEK, IoT device, secure smart energy meter and blockchain-enabled gateway, which empowers prosumers, generators and consumers to become part of Serenity decentralized community. 

To activate HEPEK and enable electricity service, members will need to purchase ERGON tokens (credit card or direct debit facility) by using Serenity app or web portal.
HEPEK will automatically open Serenity Payment Channel, off-chain verification where two (or more) connected parties perform multiple transactions without broadcasting them to the network. Instead, once users close the channel, the final balance is mined and added to the blockchain in one go. Only two transactions with blockchain will be required, one to open channel and one two close it. Such approach makes payments fast, scalable and private with minimal network fee (gas).
While ERGON balance is above low threshold, HEPEK will allow electricity consumption by enabling the smart meter, paying via a payment channel at each billing cycle in real-time. Members will be able to top-up ERGON tokens deposits inside HEPEK wallet at any time.

The smart energy broker role will be achieved through implementation of machine learning and AI cloud-based capabilities. Daily, weekly, monthly, seasonal patterns in electricity consumption and production will be analyzed in real-time in conjunction with wholesale spot prices and demand-response events to optimize usage, minimize cost and maximize profit for all Serenity members.
This appliance is integrated with the local electrical installation and connection to the Internet and GPS. HEPEK gateway will measure indoor and outdoor temperature, battery level, electricity inflow and outflow and communicate with the blockchain.

BLOCK DIAGRAM




FUNCTIONAL FLOW CHART



HEPEK REGISTRATION

Each manufactured HEPEK will have its identification number registered in Registry Smart Contract. 
Only registered gateways will be allowed to report readings and send transactions. The device identification number will be stored to an address created by Serenity on Ethereum blockchain.
A shipped gateway must be registered by the member using same HEPEK identification number. After registration finished, HEPEK will begin signing messages from secure hardware enclave and behave as a self-sufficient entity registered with Serenity and owned by the member.

HEPEK USAGE

Wholesale electricity market must be balanced nearly precisely, meaning load on the electrical grid must match generation at any given point in time; otherwise, high-voltage or low-voltage damaging situations could occur. Independent system operators have created different markets to achieve grid balance, incentivizing different parties. Some of the largest are predictive, real-time and demand response. 

Energy storage, batteries, are the best resource to be controlled by HEPEK in real-time. Serenity members with given access to the wholesale market real-time pricing and energy storage available can benefit the most and generate revenue from temporal energy arbitrage. Buying electricity when cheaper and selling it back or consuming when energy is expensive.
On demand-response markets, consumers who have flexibility in their loads are incentivized to shut down those loads for a short period and lower demand. Access to this is another opportunity for Serenity members to react to dynamics of demand response market and if HEPEK is configured to do so, it can turn off AC and broadcast bid through Serenity to demand response market generate another revenue stream.

Also, HEPEK will regulate indoor temperature through monitoring peak and off-peak periods by selecting a time when electricity is cheaper to cool down home just before the time when peak pricing kicks in and save even more.
By connecting more IoT enabled appliances to HEPEK, the device will be able to make more smart consumption decisions.

TYPICAL CONFIGURATIONS

Case 1: Consumer Mode

Member only consumes electricity from the grid; no installed solar panels or batteries:

1.	Serenity member purchases ERGON tokens which will be redeemed for right (credit) to consume electric energy.
2.	After purchase authorized Serenity Smart Contract will increase ERGON token supply and send ERGONS to HEPEK wallet and top up consumer’s balance with new created ERGON tokens.
3.	Hepek opens payment channel with Smart Contract and while ERGON balance is positive smart meter is enabled and household can use the grid electricity.
4.	Automatic payment options will be optional.

Case 2: Prosumer Mode

Prosumer is a consumer capable of exporting electricity, a part consumer – a part generator. Prosumer has installed either solar panels or batteries or both. Prosumer can top-up his ERGON token balance, similar like consumer, to pay for electricity consumption from the grid when there is no sunlight, or its batteries are empty. Prosumer’s account will be awarded when renewable energy exported to the grid. Serenity will broadcast DEMAND event to all prosumers. Hepek exports generated renewable energy in response on DEMAND even exporting energy straight from invertors either by converting solar or draining the batteries. If DEMAND is not active, all solar produced energy should be used to recharge the batteries or to run household appliances.

Hepek calls smart contract passing
•	Energy reading IN
•	Energy reding OUT
•	Battery LEVEL 

Smart Contract creates ERGON tokens and assigns them to prosumer’s account.

Case 3: Generator Mode

Generator is commercial member running solar/wind farm and producing renewable energy only.
For such a members DEMAND will be always active, solar produced energy will be exported to the grid.

Smart Contract creates ERGON tokens and updates generator’s wallet.

