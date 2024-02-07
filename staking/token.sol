pragma solidity ^0.8.0; 
interface TokenSmartIterface {
    function transfer(
    address _to, 
    uint _value
    ) external payable;
    function transferFrom(
    address _from, 
    address _to, 
    uint _value
    ) external payable;
} 
contract stakingToken {
    struct tokenValue {
        uint256 quantity;
        uint256 timestamp;
        uint256 quantityPlus;
    }

    mapping(address => mapping(address => tokenValue)) public tokens; 
    mapping(address => uint256) public smartsRewardsPerInterval;
    address public owner;
    uint256 public countStakers = 0;
    uint256 public interval = 86400;
    uint256 public endedTimestamp = 0;

    constructor() {
        owner = msg.sender;
    } 
    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    } 
    modifier onlyPayloadSize(uint size) {
        require(!(msg.data.length < size + 4),"Payload error");
        _;
    } 
    function calcRewards(address _user, address _tokenContract) private returns(uint256) {
        if (endedTimestamp > 0) {
            return ((endedTimestamp - tokens[_user][_tokenContract].timestamp)*smartsRewardsPerInterval[_tokenContract]/interval)*tokens[_user][_tokenContract].quantity;
        }
        return ((block.timestamp - tokens[_user][_tokenContract].timestamp)*smartsRewardsPerInterval[_tokenContract]/interval)*tokens[_user][_tokenContract].quantity;
    }
    

    function stake(address _tokenContract, uint _value) public onlyPayloadSize(2 * 32)  {
        require(smartsRewardsPerInterval[_tokenContract]>0, "This address not allowed");
        TokenSmartIterface(_tokenContract).transferFrom(msg.sender, address(this), _value);
        if (tokens[msg.sender][_tokenContract].quantity > 0) {
            tokens[msg.sender][_tokenContract].quantityPlus += calcRewards(msg.sender, _tokenContract);
            tokens[msg.sender][_tokenContract].quantity += _value;
            tokens[msg.sender][_tokenContract].timestamp = block.timestamp;
        } else {
            tokens[msg.sender][_tokenContract] = tokenValue(_value, block.timestamp, 0);
            countStakers++;
        }
    } 
    function unstake(address _tokenContract) public onlyPayloadSize(1 * 32)  {
        require(tokens[msg.sender][_tokenContract].quantity>0, "Token no found!"); 
        TokenSmartIterface(_tokenContract).transfer(msg.sender, 
            calcRewards(msg.sender, _tokenContract)+
            tokens[msg.sender][_tokenContract].quantity+
            tokens[msg.sender][_tokenContract].quantityPlus
        );
        tokens[msg.sender][_tokenContract] = tokenValue(0, 0, 0);
        countStakers--;
    } 
    function windrawRewards(address _tokenContract) public onlyPayloadSize(1 * 32)  {
        require(tokens[msg.sender][_tokenContract].quantity>0, "Token no found!"); 
        TokenSmartIterface(_tokenContract).transfer(
            msg.sender, 
            calcRewards(msg.sender, _tokenContract)+tokens[msg.sender][_tokenContract].quantityPlus
        );
        tokens[msg.sender][_tokenContract].timestamp = block.timestamp;
        tokens[msg.sender][_tokenContract].quantityPlus = 0;
    }   
    function setTokenSmartRewardsPerInterval(address _tokenContract, uint256 quantity) public onlyOwner()  { 
        smartsRewardsPerInterval[_tokenContract] = quantity;
    } 
    function setInterval(uint256 _interval) public onlyOwner()  { 
        interval = _interval;
    }
    function stop() public onlyOwner()  {
        endedTimestamp = block.timestamp;
    }
    function start() public onlyOwner()  {
        endedTimestamp = 0;
    }
}