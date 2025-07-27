// SPDX-License-Identifier: GPL-3.0-or-later
/*
    KangarooAirdrop Token Contract

    This contract is used for paying rewards to users on the KangarooDeFi platform.
    - Only the owner can set the router and lock/unlock the contract.
    - Only the router can mint new tokens as rewards.
    - Standard ERC20-like transfer, approve, and transferFrom functions are included.
    - For more information, visit: https://kangaroodefi.com
*/

pragma solidity ^0.8.1;

contract KangarooAirdrop {
    string public name = "kangaroo Airdrop";
    string public symbol = "KAP";
    uint256 public totalSupply = 0;
    uint8 public decimals = 18;
    bool lock;
    address Router;
    address Owner;
    bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    constructor(string memory _name ,string memory _symbol,uint8 _decimals) {
        Owner = msg.sender;
        name = _name;
        symbol = _symbol;
        decimals = _decimals;       
    }

    modifier onlyOwner() {
        require(msg.sender == Owner, "Not the contract Router");
        _;
    }

    modifier onlyRouter() {
        require(msg.sender == Router, "Not the contract Router");
        _;
    }

    modifier Lock() {
        require(lock == false, "Round Stop");
        _;
    }

    function ChangeOwner(address _owner) external onlyOwner {
        Owner = _owner;
    }

    function SetLock(bool _lock) external onlyOwner {
        lock = _lock;
    }

    function SetRouter(address _Router) external onlyOwner {
        Router = _Router;
    }

    function MintByRouter(address _to, uint amount) external onlyRouter {
        balanceOf[_to] += amount;
        totalSupply += amount;
        emit Transfer(address(0), _to, amount);
    }
    
    function transfer(address _to, uint256 _value) public Lock returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public Lock returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public Lock returns (bool success) {
        require(_value <= balanceOf[_from]);
        require(_value <= allowance[_from][msg.sender]);        
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        allowance[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256