pragma solidity ^0.4.24;

// ----------------------------------------------------------------------------
// 'ER' 'ERGON' token contract
//
// Symbol      : ER
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
    
    function SC_IncreaseSupply(address to, uint topup) public returns (bool success);
    function SC_DecreaseSupply(address _from, uint tokens) public returns (bool success);
    function SC_GetBalance(address tokenOwner) public constant returns (uint balance);
    
    function SC_Consumer(address _from, uint energy_reading) public returns (bool success);
    
    function SC_Prosumer(address _from, uint energy_readingIN, uint energy_readingOUT, uint batteryLevel) public returns (bool success);
    function UpdateDemand(uint high_treshold) public returns (bool status);
    function offDemand() public returns (bool status);
    function SC_useTokens(address toggle) public;
    function SC_getTokenStatus(address toggle) public view returns (bool status);
    
    function SC_Generator(address _from, uint energy_reading) public returns (bool success);
    

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    
    event Low_Treshold(uint tokens);
    event Alert_Treshold(uint tokens);
}


// ----------------------------------------------------------------------------
// Contract function to receive approval and execute function in one call
//
// Borrowed from MiniMeToken
// ----------------------------------------------------------------------------
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}


// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = 0x202a062c9fc9ed80cfa2e2e69e94f6b5f14bf0c2;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}


// ----------------------------------------------------------------------------
// ERC20 Token, with the addition of symbol, name and decimals and a
// fixed supply
// ----------------------------------------------------------------------------
contract FixedSupplyToken is ERC20Interface, Owned {
    using SafeMath for uint;

    string public symbol;
    string public  name;
    bool public demand;
    uint public upper_limit;
    uint private counter;
    uint public totalsupply;
    mapping(address => bool) useTokens;
    mapping(address => uint) lastReadingIN;
    mapping(address => uint) lastReadingOUT;
    mapping(address => uint) balances;
    mapping(address => uint) capacity;
    mapping(address => mapping(address => uint)) allowed;

    
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
    // Get Balance
    // ------------------------------------------------------------------------
    function SC_GetBalance(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }
    
    // ------------------------------------------------------------------------
    // Decrease Supply
    // ------------------------------------------------------------------------
    function SC_DecreaseSupply(address _from, uint tokens) public returns (bool success) {
        balances[_from] = balances[_from] - tokens;
        totalsupply = totalsupply - tokens;
        return true;
    }
    
    // ------------------------------------------------------------------------
    // Increase Supply
    // ------------------------------------------------------------------------
    function SC_IncreaseSupply(address to, uint topup) public returns (bool success) {
        balances[to] = balances[to] + topup;
        totalsupply = totalsupply + topup;
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
    // Consumer
    // ------------------------------------------------------------------------
    function SC_Consumer(address _from, uint energy_reading) public returns (bool success)
    {
        if (energy_reading > lastReadingIN[_from])
        {
            SC_DecreaseSupply(_from, energy_reading - lastReadingIN[_from]);
            lastReadingIN[_from] = energy_reading;
        }
        
        if (balances[_from] < 10)
        {
            emit Alert_Treshold(balances[_from]);
        }
        if (balances[_from] == 0)
        {
            emit Low_Treshold(balances[_from]);
        }
        return true;
    }

    // ------------------------------------------------------------------------
    // Prosumer
    // ------------------------------------------------------------------------
    function SC_Prosumer(address _from, uint energy_readingIN, uint energy_readingOUT, uint batteryLevel) public returns (bool success) 
    {
        if (demand == true && useTokens[_from] == true)
        {
            if (counter < upper_limit)
            {
                if(energy_readingIN > lastReadingIN[_from] || energy_readingOUT > lastReadingOUT[_from])
                {
                    if((energy_readingIN - lastReadingIN[_from]) < (energy_readingOUT - lastReadingOUT[_from]))
                    {
                        SC_IncreaseSupply(_from, (energy_readingOUT - lastReadingOUT[_from]) - (energy_readingIN - lastReadingIN[_from]));
                        counter = counter + (energy_readingOUT - lastReadingOUT[_from]);
                    }
                    else if((energy_readingIN - lastReadingIN[_from]) > (energy_readingOUT - lastReadingOUT[_from]))
                    {
                        SC_DecreaseSupply(_from, (energy_readingIN - lastReadingIN[_from]) - (energy_readingOUT - lastReadingOUT[_from]));
                        counter = counter + (energy_readingOUT - lastReadingOUT[_from]);
                    }
                    
                    lastReadingIN[_from] = energy_readingIN;
                    lastReadingOUT[_from] = energy_readingOUT;
                }
            }
        }
        else if(useTokens[_from] == true)
        {
           SC_Consumer(_from, energy_readingIN);
           return true;
        }
        else if(demand == true)
        {
            if (counter < upper_limit)
            {
               if (energy_readingOUT > lastReadingOUT[_from])
                {
                    SC_IncreaseSupply(_from, energy_readingOUT - lastReadingOUT[_from]);
                    counter = counter + (energy_readingOUT - lastReadingOUT[_from]);
                    lastReadingOUT[_from] = energy_readingOUT;
                }
            }
        }
        if (balances[_from] < 10)
        {
           emit Alert_Treshold(balances[_from]);
        }
        if (balances[_from] == 0)
        {
           emit Low_Treshold(balances[_from]);
        }
        capacity[_from] = batteryLevel;
        return true;
    }

    // ------------------------------------------------------------------------
    // Pure Generator
    // ------------------------------------------------------------------------
    function SC_Generator(address _from, uint energy_reading) public returns (bool success)
    {
        if (counter < upper_limit)
        {
            if (energy_reading > lastReadingOUT[_from])
            {
                SC_IncreaseSupply(_from, energy_reading - lastReadingOUT[_from]);
                counter = counter + (energy_reading - lastReadingOUT[_from]);
                lastReadingOUT[_from] = energy_reading;
            }
            return true;
        }
    }


    // ------------------------------------------------------------------------
    // Demand Event Update
    // ------------------------------------------------------------------------
    function UpdateDemand(uint high_treshold) public returns (bool status)
    {
        if (msg.sender == owner)
        {
            if(demand == false)
            {
                demand = true;
            }
            upper_limit = high_treshold;
            return demand;
        }
        counter = 0;
    }
    
    // ------------------------------------------------------------------------
    // Turn Off Demand Event
    // ------------------------------------------------------------------------
    function offDemand() public returns (bool status)
    {
        if (msg.sender == owner)
        {
            if(demand == true)
            {
                demand = false;
            }
            return demand;
        }
        counter = 0;
    }
    
    
    // ------------------------------------------------------------------------
    // Get the token balance for account `tokenOwner`
    // ------------------------------------------------------------------------
    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }


    // ------------------------------------------------------------------------
    // Transfer the balance from token owner's account to `to` account
    // - Owner's account must have sufficient balance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transfer(address to, uint tokens) public returns (bool success) {
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
    function approve(address spender, uint tokens) public returns (bool success) {
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
    // Token owner can approve for `spender` to transferFrom(...) `tokens`
    // from the token owner's account. The `spender` contract function
    // `receiveApproval(...)` is then executed
    // ------------------------------------------------------------------------
    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }


    // ------------------------------------------------------------------------
    // Don't accept ETH
    // ------------------------------------------------------------------------
    function () public payable {
        revert();
    }


    // ------------------------------------------------------------------------
    // Owner can transfer out any accidentally sent ERC20 tokens
    // ------------------------------------------------------------------------
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
}