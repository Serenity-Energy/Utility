pragma solidity ^0.4.18;

contract ERC621 {

    // Events
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval( address indexed owner, address indexed spender, uint value);

    // Stateless functions
    function totalSupply() view public returns (uint supply);
    function balanceOf( address who ) view public returns (uint value);
    function allowance(address owner, address spender) view public returns (uint value);

    // Stateful functions
    function transfer( address to, uint value) public returns (bool ok);
    function transferFrom( address from, address to, uint value) public returns (bool ok);
    function approve(address spender, uint value) public returns (bool ok);

    // Admin only functions
    function increaseSupply(uint value, address to) public returns (bool ok);
    function decreaseSupply(uint value, address from) public returns (bool ok);

}
