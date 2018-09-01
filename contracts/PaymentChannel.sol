pragma solidity ^0.4.18;

import 'zeppelin-solidity/contracts/token/ERC20.sol';

/**
 * @title Channels
 * @author Carlos Beltran <imthatcarlos@gmail.com>
 *
 * @dev Ethereum payment channels allow for off-chain transactions with an on-chain
 * settlement. Parties open one channel with a deposit, continue to sign and verify
 * transactions off-chain, and close the channel with one final transaction, on-chain.
 * This implementation only allows for one active channel between two
 * accounts, in one direction (Alice -> Bob && Bob -> Alice)
 */
contract TokenChannels {

  //============================================================================
  // EVENTS
  //============================================================================

  event ChannelOpened(bytes32 id);
  event ChannelClosed(bytes32 id, uint withChallengePeriod);
  event ChannelChallenged(bytes32 id, address by, uint value);
  event ChannelFinalized(bytes32 id, address by, uint value);

  //============================================================================
  // STORAGE
  //============================================================================

  enum ChannelState { Open, Closing, Closed }

  struct Channel {
    address sender;
    address recipient;
    address token;
    uint deposit;
    uint challenge;
    uint nonce;
    uint closeTime;
    uint value;
    ChannelState state;
  }

  mapping (address => uint) balances;
  mapping (bytes32 => Channel) channels;
  mapping (address => mapping(address => bytes32)) activeIds;

  //============================================================================
  // MODIFIERS
  //============================================================================

  modifier validChannel(bytes32 id) {
    require(channels[id].deposit != 0);
    _;
  }

  modifier notClosed(bytes32 id) {
    require(channels[id].state != ChannelState.Closed);
    _;
  }

  modifier onlyParties(bytes32 id) {
    require(msg.sender == channels[id].sender || msg.sender == channels[id].recipient);
    _;
  }

  //============================================================================
  // PUBLIC FUNCTIONS
  //============================================================================


  /**
   * Open a new channel with the recipient. Require a non-zero message
   *
   * @param token     Address of the token contract
   * @param recipient Account address of the other party
   * @param amount    Number of tokens to send
   * @param challenge Optional challenge period for either party to close the channel
   */
  function openChannel(address token, address recipient, uint amount, uint challenge)
    public
    payable
  {
    // sanity checks
    require(amount != 0 && amount == msg.value);
    require(recipient != msg.sender);
    require(activeIds[msg.sender][recipient] == bytes32(0));

    // create a channel with the id being a hash of the data
    bytes32 id = keccak256(msg.sender, recipient, now);

    Channel memory newChannel;
    newChannel.deposit = msg.value;
    newChannel.sender = msg.sender;
    newChannel.recipient = recipient;
    newChannel.token = token;
    newChannel.challenge = challenge;
    newChannel.state = ChannelState.Open;

    // make the deposit
    ERC20 tokenObject = ERC20(token);
    require(tokenObject.transferFrom(msg.sender, address(this), amount));

    // add it to storage and lookup
    channels[id] = newChannel;
    activeIds[msg.sender][recipient] = id;

    ChannelOpened(id);
  }

  /**
   * Close a channel. Only the recipient can close it.
   * The "value" is sent to the recipient and the rest refunded to the sender
   *
   * @param h     signature with data = [id, message_hash, r, s]
   * @param v     Component of signature "h" from sender
   * @param value Amount in wei to be sent
   * @param nonce Number to be hashed with the value to form the message
   */
  function closeChannel(bytes32[4] h, uint8 v, uint256 value, uint256 nonce)
    public
    notClosed(h[0])
  {
    Channel storage channel = channels[h[0]];

    // only recipient may close
    require(channel.recipient == msg.sender);

    // validate signature data
    require(verifyMsg(h, v, value));

    if (channel.challenge == 0) {
      // if there's no challenge period, close the channel

      // pay the recipient and refund the remainder to the sender
      ERC20 tokenObject = ERC20(channel.token);
      require(tokenObject.transfer(channel.recipient, value));
      require(tokenObject.transfer(channel.sender, (channel.deposit - value)));

      // close the channel
      channel.state = ChannelState.Closed;

      // update the final value
      channel.value = value;

      // remove from lookup
      delete activeIds[channel.sender][channel.recipient];

      ChannelFinalized(h[0], msg.sender, channel.value);
    } else {
      // update the channel and allow challenges

      channel.nonce = nonce;
      channel.value = value;
      channel.closeTime = now;
      channel.state = ChannelState.Closing;

      ChannelClosed(h[0], now + channel.challenge);
    }
  }

  /**
   * During the challenge period, either party can submit a proof that contains
   * a higher nonce
   *
   * @param h     signature with data = [id, message_hash, r, s]
   * @param v     Component of signature "h" from sender
   * @param value Amount in wei to be sent
   * @param nonce Number to be hashed with the value to form the message
   */
  function challenge(bytes32[4] h, uint8 v, uint256 value, uint256 nonce)
    public
    validChannel(h[0])
    notClosed(h[0])
    onlyParties(h[0])
  {
    Channel storage channel = channels[h[0]];

    // make sure we're in the challenge period
    require(channel.closeTime + channel.challenge > now);

    // make sure the nonce is higher
    require(channel.nonce < nonce);

    // validate signature data
    require(verifyMsg(h, v, value));

    // update the channel
    channel.nonce = nonce;
    channel.value = value;

    ChannelChallenged(h[0], msg.sender, value);
  }

  /**
   * After the challenge period passes, close the channel and disburse the funds
   *
   * @param id Channel id
   */
  function finalize(bytes32 id)
    public
    validChannel(id)
    notClosed(id)
    onlyParties(id)
  {
    Channel storage channel = channels[id];

    // make sure the challenge period is over
    require(channel.closeTime + channel.challenge > now);

    // pay the recipient and refund the remainder to the sender
    ERC20 tokenObject = ERC20(channel.token);
    require(tokenObject.transfer(channel.recipient, channel.value));
    require(tokenObject.transfer(channel.sender, (channel.deposit - channel.value)));

    // close the channel
    channel.state = ChannelState.Closed;

    // remove from lookup
    delete activeIds[channel.sender][channel.recipient];

    ChannelFinalized(id, msg.sender, channel.value);
  }

  /**
   * Verify that the message sent is valid
   * All messages must be signed by the channel sender
   *
   * @param h     signature with data = [id, message_hash, r, s]
   * @param v     Component of signature "h" from sender
   * @param value Amount in wei to be sent
   */
  function verifyMsg(bytes32[4] h, uint8 v, uint value)
    public
    validChannel(h[0])
    constant
    returns (bool)
  {
    // testrpc and parity adds prefix when signing
    // https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_sign
    bytes memory prefix = "\x19Ethereum Signed Message:\n32";
    bytes32 prefixedHash = keccak256(prefix, h[1]);

    address signer = ecrecover(prefixedHash, v, h[2], h[3]);
    if (signer != channels[h[0]].sender) { return false; }

    // TODO: can we verify hash message like this?
    // validate that the hash is of the channel id and with the right value
    /* bytes32 proof = keccak256(h[0], value);
    proof = keccak256(prefix, proof);

    if (proof != prefixedHash) { return false; } */

    if (value > channels[h[0]].deposit) { return false; }

    return true;
  }

  //============================================================================
  // EXTERNAL FUNCTIONS
  //============================================================================

  function getChannelId(address sender, address recipient)
    external
    view
    returns (bytes32)
  {
    return activeIds[sender][recipient];
  }

  function getChannel(bytes32 id)
    external
    validChannel(id)
    view
    returns (
      address sender,
      address recipient,
      uint deposit,
      address token,
      ChannelState state,
      uint value
    )
  {
    Channel memory channel = channels[id];

    sender = channel.sender;
    recipient = channel.recipient;
    deposit = channel.deposit;
    token = channel.token;
    state = channel.state;
    value = channel.value;
  }

  function getChannelStatus(bytes32 id)
    external
    validChannel(id)
    constant
    returns (ChannelState)
  {
    return channels[id].state;
  }

  function getChannelRemainingChallengePeriod(bytes32 id)
    external
    validChannel(id)
    constant
    returns (uint)
  {
    if (channels[id].closeTime == 0) { return 0; }
    else if (channels[id].closeTime + channels[id].challenge < now) { return 0; }
    else { return (channels[id].closeTime + channels[id].challenge) - now; }
  }
}
