contract example {
    address public owner;
    address public randomizer;
    uint256 public random;
    constructor() {
        owner = msg.sender;
        random = 0;
    }
    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    } 
    // set randomizer smart address
    function setRandomizer(address _randomizer) external onlyOwner()  {
        randomizer = _randomizer;
    }
    // set random value from randomizer
    function setRandom(uint256 number) external {
        require(randomizer == msg.sender, "Caller is not the randomizer provider");
        require(random == 0, "Random not need");
        random = number;
    }
    // call for check, is random need
    function isRandomNeed() public view returns(bool value){
      return random==0;
    }

    // for test
    function setRandomNeeded() external {
        random = 0;
    }
}