# RNGESUS
RNGesus is aimed to be a secure, trustless, distributed Random Number Generation, following Vitalik's proposed [RanDAO++](https://www.reddit.com/r/ethereum/comments/4mdkku/could_ethereum_do_this_better_tor_project_is/d3v6djb)  with small tweaks.

### Similar Work
#### RanDAO
RanDAO works via a commitment scheme where participants submit hashes and reveal their secret later on to calculate a random number. The main problem with this scheme is that the resulting random number can be calculated in a straightforward manner, allowing an attacker to manipulate the result through participating with many nodes and then determining which combination of reveals allow the best outcome. 

RanDAO mitigates this problem by charging a security deposit for nodes that do not reveal. Assuming a lottery with $1,000,000 payoff, a dishonest participant can amass m lottery tickets and decide on the combination of reveal. This gives the participant  `2**m`  chances for m lottery tickets bought. This increases exponentially for each additional ticket bought: `2**m - 2**(m-1)`, so that the potential rewards will always outgrow the linearly growing disincentives which require an **exceedingly high security deposit**. 

Reward for Attacker must be less than cost incurred: `(1 - ( (n-1)/n )**(2**m)) * 1e6 < Cm` where C is cost of ticket + security deposit. An expert will have to confirm the calculations and find the exact point where marginal gains = marginal cost, but to simplify things for this lottery, we assume 1 million people (greater = lower deposit) each paying 1 dollar to enter and calculate the security deposit, input `(1-( (1e6-1)/1e6 )^(2^m))  * 1e6 < m C` into WolframAlpha and vary m to find C: m=2, C >= 4; m=7, C >= 19; m=10, C >=  102 etcetc


#### RanDAO++
Proposed by Vitalik [here](https://www.reddit.com/r/ethereum/comments/4mdkku/could_ethereum_do_this_better_tor_project_is/d3v6djb), it goes down to 2 principles: 
1. It should not be possible for a participant to calculate fast enough the end result, which prevents the participant from knowing beforehand the effect of his/her action 
2. The end result should be tamper proof, meaning that everything submitted will be used no matter what, even if someone does not reveal the hash result of sha3^10000000 it can be calculated.

The only downside would be the costly calculation and countless verifications scaling with number of participants. Despite being O(log(n)), proper interactive verification will need many blocks, and might be infeasible for many applications.


## Implementation
RNGesus follows the implementation detailed [here](https://www.reddit.com/r/ethereum/comments/4vg3gq/rngesus_randao_variant_for_more_secure/d5y74to):

1. Upon request for a random number, wait for the next block
2. `SHA^N (block hash)` will be the random result, where N is such that it should be infeasible for miners to precalculate the result of a block hash that they find within the average block time. Upon the creation of the DAO there might have to be a difficulty adjustment phase where people are incentivized to precalculate a block hash within one block.
3. Interactive verification will be done to verify the submitted result. Participants will keep a security deposit in the DAO to participate. The security deposits will be used to pledge for the correctness of the result, and will be paid to successful challengers.
4.(Optional) Keep the flood phase idea to drastically cut down attacker's time to react, splitting incentives to the last few participants who submit their randomness before the block time. This will help cut down the cost & time of interactive verification by requiring a much lower difficulty. Will implement if there is demand.

## Incentives
Incentives will depend mainly on the exact implementation of interactive verification. 

### Stakeholders Participate
This is the safest method when the stakes are high to prevent collusion. By letting any interested stakeholder to participate, they can prevent collusion against them. Yet this is the least user friendly method as it requires end users to have a daemon with synced node to run it. All in all, this is definitely an improvement for commercial applications like lotteries, as end users at least have the choice to prevent collusion. If not, they probably never cared for that in the first place and is fine with trusting the lottery owner.

### Dedicated Verifiers
This follows the concept of having security guards doing checks, who are in turn consistently paid for their efforts. A requesting party will have to pay for the randomness due to gas & electricity costs for interactive verification. As such it is highly possible that the requesting party pay for the level of security desired, in the form of number of verifiers needed to verify the result. Yet given high enough stakes, it is still feasible for attackers to collude and bribe the verifiers. Essentially this will suffer from the same problem as RanDAO, leading to exorbitant amounts of security deposits for verifiers to ensure non-profitable collusion. The question then is whether it's worth paying for and trusting these security guards.
