pragma solidity ^0.4.18;

import 'zeppelin-solidity/contracts/ECRecovery.sol';
import 'zeppelin-solidity/contracts/ownership/Ownable.sol';
import 'zeppelin-solidity/contracts/math/SafeMath.sol';
import './RingSig.sol';

contract PPoL is Ownable, RingMixerV2 {
  using SafeMath for uint256;

  modifier onlyNode { require(isVerifyingNode(msg.sender)); _; }

  address[] verifyingNodes;
  mapping(address => uint256) verifyingNodeID;
  mapping(address => uint256) nodePublicKey;

  function PPoL() public {
    verifyingNodes.push(address(0));
  }

  function addVerifyingNode(address _node, uint256 _pubKey) public onlyOwner returns(bool success) {
    if (_node == address(0)) { return false; }
    verifyingNodes.push(_node);
    verifyingNodeID[_node] = verifyingNodes.length.sub(1);
    nodePublicKey[_node] = _pubKey;
    return true;
  }

  function removeVerifyingNode(address _node) public onlyOwner returns(bool success) {
    if (!isVerifyingNode(_node)) { return false; }
    delete verifyingNodes[verifyingNodeID[_node]];
    delete verifyingNodeID[_node];
    delete nodePublicKey[_node];
    return true;
  }

  function isVerifyingNode(address _node) public view returns(bool) {
    return verifyingNodeID[_node] != 0;
  }

  function ringSign(bytes _message, uint256 _prvKey, uint256[] _dummyNodeIDs, uint256[] _randNums)
    public view returns(uint256[32] signature, bool success)
  {
    uint256[32] memory empty;
    if (!isVerifyingNode(msg.sender)
        || _dummyNodeIDs.length != _randNums.length
        || _dummyNodeIDs.length.mul(2).add(1) >= 32)
    {
      return (empty, false);
    }

    uint256 N = _dummyNodeIDs.length;
    uint256[] memory data = new uint256[](32);
    uint256 i = 0;

    data[0] = 0;
    data[1] = _prvKey;
    for (i = 0; i < N; i = i.add(1)) {
      if (!isVerifyingNode(verifyingNodes[_dummyNodeIDs[i]])) { return (empty, false); }
      data[i.add(2)] = _randNums[i];
      data[i.add(2).add(N)] = nodePublicKey[verifyingNodes[_dummyNodeIDs[i]]];
    }
    return (RingSign(_message, data), true);
  }

  function verifyProof(uint256 _timestamp, address _userAddr, bytes _userSig,
    uint256[] _ringSig)
    public view returns(bool isValid)
  {
    return ECRecovery.recover(keccak256(_timestamp), _userSig) == _userAddr
      && RingVerify(_userSig, _ringSig);
  }
}
