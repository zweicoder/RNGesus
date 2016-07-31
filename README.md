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
RNGesus mainly follows the implementation of RanDAOplusplus for now, with some changes:

#### Submission phase
1. Participants asking for the randomness (e.g. everyone who bought a lottery ticket) are given a timeframe to submit their own string / hash. 
2. This phase can last as long as required, and should be a comfortable timeframe for all participants to submit their randomness to prevent others from colluding against them.

#### Flood phase
1. The dedicated people who are part of RNGesus, so called RNG miners, along with any other willing participant will flood the submissions with more randomness. RNG miners will run daemons listening to Events to facilitate this phase.
2. This phase should last much shorter than the submission phase, maybe 1 minute or less, severely constraining the amount of time someone has to calculate the end result.

#### Verification phase
1. At the end of the Flood phase, participants will do f(sha(s1),sha(s2), ..., sha(sn) where f is a reducer using a simple XOR operation or SHA again. We then do sha^1e10 on the result. Idea here (might be mistaken) is that repeated hash operations cannot be performed in parallel, so doing it once with large enough hash operations is good enough.
2. Participants are incentivized to solve and submit a correct result.
3. Interactive verification can be done to verify the submitted result
4. Vary difficulty depending on time taken to solve it.


#### Verification phase ++ (KIV)
This is a potential improvement to the current proposed system, using a PoW style method to get a solution that can be verified on-chain. 
1. At the end of the Flood phase, participants will do f(sha(s1),sha(s2), ..., sha(sn) where f is a reducer using a simple XOR operation or SHA again. This will be the seed hash.

2. The seed hash is used along with a nonce to calculate a solution hash that is below a difficulty level. Done correctly, it might even be feasible for the EVM to calculate the seed hash. Thenafter we can verify on-chain whether the sha(nonce + seed hash) = solution hash.

3. The difficulty level must ensure that cheating the system under the time constraints require economically infeasible levels of computation. E.g. if the potential rewards are $1m, difficulty level must be such that attacker requires a hash rate costing C to find the solution first with probability x%, giving him additional y% chance to win: `Cxy > R = 1e6`

4. The difficulty level can be dependent on the number of participant if there are no dedicated 'miners', so that participants themselves can solve it given a reasonable timeframe, but the attacker cannot calculate the result fast enough to react and manipulate the result during the flood phase

5. If there are dedicated 'miners', it can be dependent of their hash rate, but I'm not sure if there will be enough incentive to consistently mine the solution for random numbers. If so, we can follow what Vitalik suggested and have a period when the DAO is created to reward people who can calculate fast enough the result, and vary the difficulty as needed.
