import "CheapArray.sol";

contract Rngesus {
    address developer;
    mapping(uint => PendingResult) requests;
    mapping(uint => Challenge) challenges;
    mapping(address=>uint) deposit;
    uint public MIN_DEPOSIT; // This must be enough to cover the gas from verisha
    uint public CURRENT_DIFFICULTY;
    uint public THRESHOLD;

    struct PendingResult {
        bool initialized;
        bytes32 value;
        address insurer;
    }

    struct Challenge {
        bytes32 left;
        bytes32 right;
        address leftPlayer;
        address rightPlayer;
        uint[9] indices; // hardcode branching factor for now
        using CheapArray for bytes32[] lbranches;
        using CheapArray for bytes32[] rbranches;
    }

    event Event_Challenged(address insurer, address msg.sender, uint blockNum, uint[10] indices);

    modifier hasSecurityDeposit() {
        if (deposit[msg.sender] < MIN_DEPOSIT) {
            throw;
        }
        _
    }

    function Rngesus() {
        developer = msg.sender;
        MIN_DEPOSIT = 1 ether;
        CURRENT_DIFFICULTY = 4 000 000 0 // takes one minute on my computer. adjust as needed
        THRESHOLD = 1 000 00 // 1 cents
    }

    function () {
        throw;
    }

    function shatest(uint n) constant {
        // 65  gas per sha, gas price is around 0.000 000 0225, so around 1 million shas will cost 0.1 eth
        // 1 million shas ~= 1.5s on my computer
        var x = msg.sender;
        for (uint i=0; i<n; i++){
            x = sha3(x);
        }
    }

    function requestRng() {
        // RNG calculated for block after the requested one
        var target = block.number + 1;
        if (!requests[target].initialized) {
            // RNG already requested
            throw;
        }

        requests[target] = PendingResult(true, 0, 0x0);
    }

    function submitSolution(uint blockNum, bytes32 attempt) hasSecurityDeposit {
        if (!requests[blockNum].initialized) {
            throw;
        }

        if (requests[blockNum].value == 0) {
            // No value submitted yet
            requests[blockNum].insurer = msg.sender;
            requests[blockNum].value = attempt;
            return;
        }

        if (requests[blockNum].value == attempt) {
            return;
        }

        // Answers are different, have them fight it out or the default one wins.
        // Time before it expires? Person who doesn't reveal solution in time limit loses by default? Insurers lose as well? Is there a need for multiple insurers?
        // Careful of recursive calls here. Might have to check if challenge already requested
        veriSha(requests[blockNum].insurer, msg.sender, blockNum);


    }

    // TODO split logic to another contract / library
    function veriSha(address insurer, address challenger, uint blockNum) internal {
        // Initialize Challenge
        var left = block.blockhash(blockNum);
        var right = requests[blockNum].value;
        challenges[blockNum] = Challenge(left, right, insurer, challenger);

        // This event is mainly to alert stakeholders to submit the indices requested
        Event_Challenged(blockNum, getBranchIndices(0, CURRENT_DIFFICULTY));
    }

    function getBranchIndices(start, end) internal returns (uint[9]) {
        var d = start + end;
        return [start, d/8, d/4, d*3/8, d/2, d*5/8, d*3/4, d*7/8, end];
    }

    // Method that players of the interactive verification game will call.
    function doChallenge(uint blockNum, bytes32[] branches) {
        if (branches.length != 9 ) throw; // For now just throw if input is invalid. CheapArray needs some sort of constructor
        if (branches[0] != challenge.left || branches[branches] != challenge.right) throw; // Left and right are already agreed upon, deny input mismatch
        if (!updateMoves(blockNum)) return; // Wait for the other player. TODO check if time expired

        // Both have submitted the X number of branches
        var (leftIdx, rightIdx) = findBranch(blockNum);
        updateChallenge(blockNum, leftIdx, rightIdx);

    }

    // Update storage with a player's move (the branches)
    function updateMoves(uint blockNum, bytes32[] branches) internal returns(bool) {
        Challenge challenge = challenges[blockNum];
        if (msg.sender != challenge.leftPlayer || msg.sender != challenge.rightPlayer) {
            // Only 1v1 for now
            throw;
        }

        if (msg.sender == challenge.leftPlayer) {
            challenge.lbranches.insertAll(branches);
        } 
        else if (msg.sender == challenge.rightPlayer) {
            challenge.rbranches.insertAll(branches);
        }

        if (challenge.lbranches.n == 0 || challenge.rbranches.n == 0) {
            // TODO confirm that storage is modified via reference
            return false;
        }

        return true;
    }

    // Here we find where things went wrong. Returns [leftIdx, rightIdx]
    function findBranch(uint blockNum) internal returns(uint leftIdx, uint rightIdx){
        Challenge challenge = challenges[blockNum];
        var leftIdx;
        var rightIdx;
        var indices = challenge.indices;
        uint8 error;
        for (uint i = 1; i < challenge.lbranches.length-1; i++) {
            if (challenge.lbranches[i] != challenge.rbranches[i]) {
                // We want to find the first place where the calculations diverged, then take the latest place where calculations are still agreed upon
                leftIdx = indices[i-1];
                rightIdx = indices[i];
                break;
            }
        }

        // Variables not set cause nothing in the branches were different. Zoom to rightmost branch.
        // This will work as long as the threshold is bigger than branching factor
        if (leftIdx == 0 && rightIdx == 0) {
            leftIdx = indices[indices.length - 2];
            rightIdx = indices[indices.length - 1];
        }

        return (leftIdx, rightIdx);
    }

    // Find out who's correct if below threshold, else update state variables and request new indices
    function updateChallenge(uint blockNum, uint leftIdx, uint rightIdx) internal {
        Challenge challenge = challenges[blockNum];

        if (rightIdx - leftIdx <= THRESHOLD) {
            // rush from challenge.left to challenge.right
            shaRush(challenge.lbranches[leftIdx], challenge.rbranches[rightIdx]);
        }
        else {
            // Update storage with new consensus
            challenge.left = challenge.lbranches[leftIdx];
            challenge.lbranches.clear();
            challenge.right = challenge.rbranches[rightIdx];
            challenge.rbranches.clear();
            challenge.indices = getBranchIndices(leftIdx, rightIdx); // TODO use CheapArray

            // Request for new indices
            Event_Challenged(blockNum, challenge.indices);
        }
    }
}

