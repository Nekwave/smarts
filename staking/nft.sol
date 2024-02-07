pragma solidity ^0.8.0;

interface NFTSmartIterface {
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable;
}
interface TokenSmartIterface {
    function transfer(
        address _to, 
        uint _value
        ) external payable;
} 

contract stakingNft {
    mapping(address => mapping(address => mapping(uint256 => uint256))) public nfts; 
    mapping(address => uint256) public smartsRewardsPerInterval;
    address public tokenSmartAddress;
    address public owner;
    uint256 public interval = 86400;
    uint256 public countNfts = 0;
    uint256 public endedTimestamp = 0;

    constructor() {
        owner = msg.sender;
    } 
    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    } 
    modifier onlyPayloadSize(uint size) {
        require(!(msg.data.length < size + 4));
        _;
    } 
    

    function stake(address _nftContract, uint _tokenId) public onlyPayloadSize(2 * 32)  {
        require(smartsRewardsPerInterval[_nftContract]>0, "This address not allowed");
        NFTSmartIterface(_nftContract).transferFrom(msg.sender, address(this), _tokenId);
        nfts[msg.sender][_nftContract][_tokenId] = block.timestamp;
        countNfts++;
    }
    function calcRewards(address _nftContract, uint _tokenId) private returns(uint256) {
        if (endedTimestamp > 0) {
            return (endedTimestamp - nfts[msg.sender][_nftContract][_tokenId])*smartsRewardsPerInterval[_nftContract]/interval;
        }
        return (block.timestamp - nfts[msg.sender][_nftContract][_tokenId])*smartsRewardsPerInterval[_nftContract]/interval;
    }
    function unstake(address _nftContract, uint _tokenId) public onlyPayloadSize(2 * 32)  {
        require(nfts[msg.sender][_nftContract][_tokenId]>0, "NFT no found!");
        sendReward(msg.sender, calcRewards(_nftContract, _tokenId));
        nfts[msg.sender][_nftContract][_tokenId] = 0;
        NFTSmartIterface(_nftContract).transferFrom(address(this),msg.sender , _tokenId);
        countNfts--;
    }
    function windrawRewards(address _nftContract, uint _tokenId) public onlyPayloadSize(2 * 32)  {
        require(nfts[msg.sender][_nftContract][_tokenId]>0, "NFT no found!");
        sendReward(msg.sender, calcRewards(_nftContract, _tokenId));
        nfts[msg.sender][_nftContract][_tokenId] = block.timestamp;
    }

    function sendReward(address target, uint256 quantity) private  {
        require(tokenSmartAddress!=address(0),"Empty token address");
        TokenSmartIterface(tokenSmartAddress).transfer(target, quantity);
    }
    function setTokenSmart(address _tokenSmartAddress)  public onlyOwner() {  
        tokenSmartAddress = _tokenSmartAddress;
    } 
    function setNftSmartRewards(address _nftContract, uint256 quantity) public onlyOwner()  {
        smartsRewardsPerInterval[_nftContract] = quantity;
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