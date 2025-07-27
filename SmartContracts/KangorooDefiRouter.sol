// SPDX-License-Identifier: GPL-3.0-or-later
/*
TODO:
The BTC UP OR DOWN Token has two main functions:
1. If the token wins the round, it saves the KWBNBs that can be minted by the routers.
2. When the round finishes, all tokens from both UP and DOWN are sent to the winning token, 
   and anyone can withdraw their share. 

We have a withdraw token address that can be set up from the router. 
After the round finishes, the total supply should match the supply of all individual tokens.

Platform: https://kangaroodefi.com
*/

pragma solidity ^0.8.1;
import "@openzeppelin/contracts/security/Pausable.sol";
// Standard ERC20 Interface for token balance checking
interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
}

// Interface for Router contract
interface IRouter {
    function AddTransaction(address user) external;
}

// Interface for Wrapped token (WToken)
interface IWtoken {
    function MintByRouter(address _to, uint amount) external;
    function BurnByRouter(address _account, uint amount) external;
    function withdraw(uint amount) external;
}

// Interface for Up/Down Token contract
interface IUDToken {
    function initialize(
        string memory _name,
        string memory _symbol,
        uint supply,
        uint8 Decimals,
        address _Collateral,
        address _reward,
        address pair
    ) external;

    function SetWin(bool iswin) external;
    function SetLock(bool _lock) external;
    function RemovePair() external;
}

// Interface for Pancakeswap V2 Factory
interface IV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint
    );

    function getPair(
        address tokenA,
        address tokenB
    ) external view returns (address pair);

    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);
}

// Interface for Pancakeswap V2 Pair
interface IV2Pair {
    function sync() external;
}

// Contract for Up/Down Token (UDToken)
contract UDToken is IERC20 {
    string public name = "UDToken";
    string public symbol = "UD";
    uint256 public totalSupply = 0;
    uint public firstSupply = 0;
    uint8 public decimals = 18;
    bool public Iswin;
    bool lock;

    address Router;
    address Collateral;
    address reward;
    address public roundpair;

    // Selector for safe token transfer
    bytes4 private constant SELECTOR =
        bytes4(keccak256(bytes("transfer(address,uint256)")));

    mapping(address => uint256) public override balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    constructor() {
        Router = msg.sender;
    }

    // Modifier to allow only Router access
    modifier onlyRouter() {
        require(msg.sender == Router, "Not the contract Router");
        _;
    }

    // Modifier to ensure round is not locked
    modifier Lock() {
        require(lock == false, "Round Stop");
        _;
    }

    // Safe transfer function for tokens
    function _safeTransfer(address token, address to, uint value) private {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(SELECTOR, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TRANSFER_FAILED"
        );
    }

    // Safe transfer function for ETH
    function _safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'ETH_TRANSFER_FAILED');
    }

    // Initializes the token with specific parameters
    function initialize(
        string memory _name,
        string memory _symbol,
        uint supply,
        uint8 Decimals,
        address _Collateral,
        address _reward,
        address pair
    ) external onlyRouter {
        name = _name;
        symbol = _symbol;
        balanceOf[pair] = supply;
        totalSupply = supply;
        Collateral = _Collateral;
        reward = _reward;
        decimals = Decimals;
        roundpair = pair;
        emit Transfer(address(0), Router, supply);
    }

    // Locking function to stop trading after round expiration
    function SetLock(bool _lock) external onlyRouter {
        lock = _lock;
    }

    // Remove liquidity pool after round ends
    function RemovePair() external onlyRouter {
        uint tempbalance = balanceOf[roundpair];
        balanceOf[roundpair] = 0;
        totalSupply -= tempbalance;
        firstSupply = totalSupply;
        emit Transfer(
            roundpair,
            address(0x000000000000000000000000000000000000dEaD),
            tempbalance
        );
    }

    // Mark the token as a winner
    function SetWin(bool iswin) external onlyRouter {
        Iswin = iswin;
    }

    // Standard ERC20 transfer function
    function transfer(
        address _to,
        uint256 _value
    ) public Lock returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        require(_to != roundpair); // Prevent selling tokens

        if(msg.sender == roundpair){
            IRouter(Router).AddTransaction(_to);
        }

        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    // Standard ERC20 approve function
    function approve(
        address _spender,
        uint256 _value
    ) public Lock returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    // Function to withdraw rewards based on token holdings
    function Withdraw(uint _amount) external {
        address withdrawAddress = Iswin ? Collateral : reward;
        require(balanceOf[msg.sender] >= _amount);

        uint256 WithdrawAmount = (_amount * IERC20(withdrawAddress).balanceOf(address(this))) / totalSupply;
        
        balanceOf[msg.sender] -= _amount;
        totalSupply -= _amount;
        emit Transfer(msg.sender, address(0x000000000000000000000000000000000000dEaD), _amount);

        if (Iswin) { // Withdraw ETH/BNB if winner, else withdraw airdrop token
            IWtoken(withdrawAddress).withdraw(WithdrawAmount);
            _safeTransferETH(msg.sender, WithdrawAmount);
        } else {
            _safeTransfer(withdrawAddress, msg.sender, WithdrawAmount);
        }
    }

    // Transfer function with allowance check
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public Lock returns (bool success) {
        require(_value <= balanceOf[_from]);
        require(_value <= allowance[_from][msg.sender]);
        require(_to != roundpair); // Prevent selling tokens

        if (_from == roundpair) {
            IRouter(Router).AddTransaction(_to);
        }

        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        allowance[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    // Event declarations
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );

    // Allow contract to receive ETH/BNB
    receive() external payable {}
}


/**
 * @title Kangaroo Router Contract
 * @dev Handles the creation and management of prediction market rounds using an Automated Market Maker (AMM) model.
 *      Users can participate in prediction rounds by purchasing Up or Down tokens, which are minted and traded.
 */
contract kangarooRouter is Pausable {    
    address private owner;

    string public constant MainAddress = "kangaroodefi.com";
    address private LoserFeesAddress; // Address where loser fees are sent
    address private Factory; // Factory address for creating token pairs
    uint private LoserReward; // Percentage of loser funds redistributed
    uint public Creatorfee; // Fee decimals: 4 (e.g., 10000 = 1%, 1000 = 0.1%)

mapping(address => bool) private Oracle; // List of approved oracle addresses
    mapping(address => bool) public Tokens; // List of valid token addresses
    mapping(address => uint) public NTransactions; // Number of transactions per 
    
    struct Rounds {
        uint Roundid;        // ID of the round
        uint openprice;      // Opening price of the asset
        uint closeprice;     // Closing price of the asset
        address UpToken;     // Address of the UP token
        address DownToken;   // Address of the DOWN token
        address UpPair;      // Address of the liquidity pair for UP token
        address DownPair;    // Address of the liquidity pair for DOWN token
        uint totalSupply;    // Total supply of tokens in the round
        uint OpenTime;       // Timestamp when the round opens
        uint CloseTime;      // Timestamp when the round closes
        uint rewardpool;     // Total reward pool of the round
    }
    mapping(uint => Rounds[]) Markets;

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    // Allows tokens to log transactions for tracking user activity
    function AddTransaction(address user) external onlyToken whenNotPaused {
        NTransactions[user]++;
    }

    // Owner can set the fee structure
    function SetFees(uint _LoserReward, uint _Creatorfee) external onlyOwner whenNotPaused {
        LoserReward = _LoserReward;
        Creatorfee = _Creatorfee;
    }

    // Owner can set the factory address
    function SetFactory(address _factory) external onlyOwner whenNotPaused {
        Factory = _factory;
    }

    // Get the latest round index of a market
    function GetLastRound(uint marketid) public view returns (uint) {
        return Markets[marketid].length;
    }

    // Retrieve details of a specific round
    function GetRound(uint marketid, uint RoundIndex) external view returns (Rounds memory) {
        return Markets[marketid][RoundIndex];
    }

    // Creates a new round with Up/Down tokens and trading pairs
    function CreateRound(uint marketid, address Collateral) external onlyOracle whenNotPaused returns (address UpToken, address DownToken, address Uppair, address Downpair) {
        uint RoundNumber = Markets[marketid].length + 1;
        UpToken = address(new UDToken{salt: keccak256(abi.encode(RoundNumber, block.timestamp, Collateral, "1"))}());
        Tokens[UpToken] = true;
        DownToken = address(new UDToken{salt: keccak256(abi.encode(RoundNumber, block.timestamp, Collateral, "2"))}());
        Tokens[DownToken] = true;
        Uppair = IV2Factory(Factory).createPair(UpToken, Collateral);
        Downpair = IV2Factory(Factory).createPair(DownToken, Collateral);
    }

    // Initialize and register token pairs for a round
    function SetPairs(string memory marketName, string memory Ticker, uint8 Decimals, uint[] memory UintEntries, address[] memory addresses) external onlyOracle whenNotPaused returns (Rounds memory) {
        IUDToken(addresses[2]).initialize(marketName, string(abi.encodePacked("UP", Ticker)), UintEntries[1], Decimals, addresses[0], addresses[1], addresses[4]);
        IWtoken(addresses[0]).MintByRouter(addresses[4], UintEntries[1]);
        IV2Pair(addresses[4]).sync();
        IUDToken(addresses[3]).initialize(marketName, string(abi.encodePacked("Down", Ticker)), UintEntries[1], Decimals, addresses[0], addresses[1], addresses[5]);
        IWtoken(addresses[0]).MintByRouter(addresses[5], UintEntries[1]);
        IV2Pair(addresses[5]).sync();
        Markets[UintEntries[0]].push(Rounds(Markets[UintEntries[0]].length, UintEntries[2], 0, addresses[2], addresses[3], addresses[4], addresses[5], UintEntries[1], UintEntries[3], 0, 0));
        return Markets[UintEntries[0]][Markets[UintEntries[0]].length - 1];
    }

    // Closes a round and distributes rewards
    function CloseRound(uint[] memory UintEntries, address Collateral, address reward, address Creator) external onlyOracle whenNotPaused {
        Rounds memory Round = Markets[UintEntries[0]][UintEntries[1] - 1];
        require(Round.openprice > 0);
        uint Longsupply = IERC20(Collateral).balanceOf(Round.UpPair) - Round.totalSupply;
        uint Shortsupply = IERC20(Collateral).balanceOf(Round.DownPair) - Round.totalSupply;
        uint _Creatorfee = 0;
        uint _LoserReward = 0;
        address WinnerAddress;
        address LoserAddress;
        if (Round.openprice <= UintEntries[2]) {
            if (Longsupply == 0) {
                _Creatorfee = (Creatorfee * Shortsupply) / 10 ** 6;
                _LoserReward = Shortsupply - _Creatorfee;
            } else {
                _Creatorfee = (Creatorfee * (Shortsupply + Longsupply)) / 10 ** 6;
                _LoserReward = (LoserReward * (Shortsupply + Longsupply)) / 10 ** 6;
            }
            WinnerAddress = Round.UpToken;
            LoserAddress = Round.DownToken;
        } else {
            if (Shortsupply == 0) {
                _Creatorfee = (Creatorfee * Longsupply) / 10 ** 6;
                _LoserReward = Longsupply - _Creatorfee;
            } else {
                _Creatorfee = (Creatorfee * (Shortsupply + Longsupply)) / 10 ** 6;
                _LoserReward = (LoserReward * (Shortsupply + Longsupply)) / 10 ** 6;
            }
            WinnerAddress = Round.DownToken;
            LoserAddress = Round.UpToken;
        }
        IUDToken(WinnerAddress).SetLock(false);
        IUDToken(LoserAddress).SetLock(false);
        IUDToken(WinnerAddress).RemovePair();
        IUDToken(LoserAddress).RemovePair();
        IWtoken(Collateral).BurnByRouter(Round.UpPair, IERC20(Collateral).balanceOf(Round.UpPair));
        IWtoken(Collateral).BurnByRouter(Round.DownPair, IERC20(Collateral).balanceOf(Round.DownPair));
        IUDToken(WinnerAddress).SetWin(true);
        IWtoken(reward).MintByRouter(LoserAddress, UintEntries[4] * (Shortsupply + Longsupply));
        IWtoken(Collateral).MintByRouter(WinnerAddress, (Shortsupply + Longsupply) - (_Creatorfee + _LoserReward));
        IWtoken(Collateral).MintByRouter(Creator, _Creatorfee);
        IWtoken(Collateral).MintByRouter(LoserFeesAddress, _LoserReward);
        Markets[UintEntries[0]][UintEntries[1] - 1].closeprice = UintEntries[2];
        Markets[UintEntries[0]][UintEntries[1] - 1].CloseTime = UintEntries[3];
        Markets[UintEntries[0]][UintEntries[1] - 1].rewardpool = Longsupply + Shortsupply;
    }

    // Lock a round to prevent further trading
    function LockRound(uint marketid, uint Roundid) external onlyOracle whenNotPaused {
        IUDToken(Markets[marketid][Roundid].UpToken).SetLock(true);
        IUDToken(Markets[marketid][Roundid].DownToken).SetLock(true);
    }

    // Unlock a round to allow trading
    function UnLockRound(uint marketid, uint Roundid) external onlyOracle whenNotPaused {
        IUDToken(Markets[marketid][Roundid].UpToken).SetLock(false);
        IUDToken(Markets[marketid][Roundid].DownToken).SetLock(false);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the contract owner");
        _;
    }
    function ChangeOwner(address _newOwner) external onlyOwner whenNotPaused {
        owner = _newOwner;
    }

    modifier onlyOracle() {
        require(Oracle[msg.sender] == true, "Not the contract Oracle");
        _;
    }
    modifier onlyToken() {
        require(Tokens[msg.sender] == true, "Not the token contract");
        _;
    }

    function ChangeLoserfeesAddress(address _newAddress) external onlyOwner whenNotPaused {
        LoserFeesAddress = _newAddress;
    }
    constructor() {
        owner = msg.sender;
        LoserFeesAddress = msg.sender;
    }
    function setOracle(address _addr, bool _value) public onlyOwner whenNotPaused {
        Oracle[_addr] = _value;
    }
}

