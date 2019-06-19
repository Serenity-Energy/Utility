pragma solidity ^0.4.24;

// ----------------------------------------------------------------------------
// 'ER' 'ERGON' token contract
//
// Symbol      : ERG
// Name        : ERGON
// ----------------------------------------------------------------------------


// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------
library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}


// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
// ----------------------------------------------------------------------------
contract ERC20Interface {
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    
    function SC_UpdateUserStatus(address _user, bool status) public returns (bool success);
    function SC_adduser(address hepekID, string userID, uint utype, uint tokenbalance) public returns (bool success);
    
    function SC_addtopup(address to, uint topup) public returns (bool success);
    
    
    function UpdateDemand(uint high_treshold) public returns (bool status);
    function offDemand() public returns (bool status);
    function SC_useTokens(address toggle) public;
    function SC_getTokenStatus(address toggle) public view returns (bool status);
    function SC_getDemandStatus() public view returns (bool status);
    function SC_returnlimit() public view returns (uint);
    
    
    function SC_channeloff(address hepekID) public returns (bool success);

    function SC_checkuser(address hepekID) public view returns (bool condition);


    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    
    event Low_Treshold(uint tokens);
    event Alert_Treshold(uint tokens);
}





// ----------------------------------------------------------------------------
// ERC20 Token, with the addition of symbol, name and decimals and a
// fixed supply
// ----------------------------------------------------------------------------
contract FixedSupplyToken is ERC20Interface {
    using SafeMath for uint;

    struct user{
        bool channel;
        uint last_topup;
        string name;
        uint usertype;
        bool activestate;
        address useraddress;
    }

    string public symbol;
    string public  name;
    bool public demand;
    uint public upper_limit;
    uint private counter;
    uint public totalsupply;
    mapping(address => bool) useTokens;

    mapping(address => uint) balances;
    
    mapping(address => mapping(address => uint)) allowed;

    mapping(address => user) public userlist;

    event update_launch(uint tokens);
    
    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor() public {
        symbol = "ER";
        name = "ERGON";
        demand = false;
        upper_limit = 0;
        totalsupply = 0;
    }
    
    
    // ------------------------------------------------------------------------
    // Returning upper limit
    // ------------------------------------------------------------------------
    function SC_returnlimit() public view returns (uint)
    {
        return upper_limit;
    }
    
    
    // ------------------------------------------------------------------------
    // Add User
    // ------------------------------------------------------------------------
    function SC_adduser(address hepekID, string userID, uint utype,uint tokenbalance) public returns (bool success)
    {
        userlist[hepekID].useraddress = hepekID;
        userlist[hepekID].name = userID;
        userlist[hepekID].usertype = utype;
        userlist[hepekID].last_topup = tokenbalance;
        userlist[hepekID].channel = true;
        balances[hepekID] = tokenbalance;
        userlist[hepekID].activestate = true;
        return true;
    }
    
    function SC_UpdateUserStatus(address _user, bool status) public returns (bool success)
    {
        userlist[_user].activestate = status;
        return true;
    }
    
    // ------------------------------------------------------------------------
    // Channel Off function
    // ------------------------------------------------------------------------
    function SC_channeloff(address hepekID) public returns (bool success)
    {
        userlist[hepekID].channel = false;
        return true;
    }
    
    // ------------------------------------------------------------------------
    // Check User Status
    // ------------------------------------------------------------------------
    function SC_checkuser(address hepekID) public view returns (bool condition)
    {
        if(userlist[hepekID].activestate == true || userlist[hepekID].useraddress == hepekID){
            return true;
        }
        return userlist[hepekID].activestate;
    }
    
    
    
    // ------------------------------------------------------------------------
    // Add Topup in user's account
    // ------------------------------------------------------------------------
    function SC_addtopup(address to, uint topup) public returns (bool success) 
    {
        balances[to] = balances[to] + topup;
        userlist[to].channel = true;
        userlist[to].last_topup = topup;
        emit update_launch(topup);
        return true;
    }
    
    // ------------------------------------------------------------------------
    // Change Tokens Button Status
    // ------------------------------------------------------------------------
    function SC_useTokens(address toggle) public
    {
        if(useTokens[toggle] == false)
        {
            useTokens[toggle] = true;
        }
        else
        {
            useTokens[toggle] = false;
        }
    }
    
    // ------------------------------------------------------------------------
    // Use Tokens Button Update
    // ------------------------------------------------------------------------
    function SC_getTokenStatus(address toggle) public view returns (bool status)
    {
        return useTokens[toggle];
    }
    
    // ------------------------------------------------------------------------
    // Get Demand Status
    // ------------------------------------------------------------------------
    function SC_getDemandStatus() public view returns (bool status)
    {
        return demand;
    }
    
    
    

    // ------------------------------------------------------------------------
    // Demand Event Update
    // ------------------------------------------------------------------------
    function UpdateDemand(uint high_treshold) public returns (bool status)
    {
        if(demand == false)
        {
            demand = true;
        }
        upper_limit = high_treshold;
        counter = 0;
        return demand;
    }
    
    // ------------------------------------------------------------------------
    // Turn Off Demand Event
    // ------------------------------------------------------------------------
    function offDemand() public returns (bool status)
    {
        if(demand == true)
        {
            demand = false;
        }
        upper_limit = 0;
        counter = 0;
        return demand;
    }
    
    
    // ------------------------------------------------------------------------
    // Get the token balance for account `tokenOwner`
    // ------------------------------------------------------------------------
    function balanceOf(address tokenOwner) public view returns (uint balance) 
    {
        return balances[tokenOwner];
    }


    // ------------------------------------------------------------------------
    // Transfer the balance from token owner's account to `to` account
    // - Owner's account must have sufficient balance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transfer(address to, uint tokens) public returns (bool success) 
    {
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }


    // ------------------------------------------------------------------------
    // Token owner can approve for `spender` to transferFrom(...) `tokens`
    // from the token owner's account
    //
    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
    // recommends that there are no checks for the approval double-spend attack
    // as this should be implemented in user interfaces 
    // ------------------------------------------------------------------------
    function approve(address spender, uint tokens) public returns (bool success) 
    {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }


    // ------------------------------------------------------------------------
    // Transfer `tokens` from the `from` account to the `to` account
    // 
    // The calling account must already have sufficient tokens approve(...)-d
    // for spending from the `from` account and
    // - From account must have sufficient balance to transfer
    // - Spender must have sufficient allowance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(from, to, tokens);
        return true;
    }


    // ------------------------------------------------------------------------
    // Returns the amount of tokens approved by the owner that can be
    // transferred to the spender's account
    // ------------------------------------------------------------------------
    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    // ------------------------------------------------------------------------
    // Don't accept ETH
    // ------------------------------------------------------------------------
    function () public payable {
        revert();
    }


}
