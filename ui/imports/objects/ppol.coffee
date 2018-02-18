Web3 = require 'web3'
web3 = window.web3
if typeof web3 != "undefined"
  web3 = new Web3(web3.currentProvider)
else
  web3 = new Web3(new Web3.providers.HttpProvider("http://localhost:8545"))

export PPoL = () ->
  self = this
  self.contract = null
  self.address = null

  self.init = (_address) ->
    self.address = _address
    abi = require("./abi/PPoL.json").abi
    self.contract = new web3.eth.Contract(abi, _address)
    web3.eth.getAccounts().then(
      (accounts) ->
        web3.eth.defaultAccount = accounts[0]
    )

  #Verifying node methods

  self.getVerifyingNodes = (_name) ->
    array = []
    return self.contract.methods["verifyingNodesCount"]().call().then(
      (_count) ->
        count = +_count
        if count == 0
          return []
        array = new Array(count)
        getItem = (id) ->
          return self.contract.methods["verifyingNodes"](id).call().then(
            (_item) ->
              return new Promise((fullfill, reject) ->
                if typeof _item != null
                  array[id] = _item
                  fullfill()
                else
                  reject()
                return
              )
          )
        getAllItems = (getItem(id) for id in [0..count - 1])
        return Promise.all(getAllItems)
    ).then(
      () ->
        return array.filter((_addr) -> _addr != "")
    )

  self.getRandomNodes = (_nodes, _num, _exclude) ->
    cp = _nodes.slice()
    result = []
    while _num > 0
      id = Math.floor(Math.random()*cp.length)
      result.push(cp[id])
      cp.remove(id)
      _num -= 1
    return result

  self.ringSign = (_userSig, _prvKey, _dummyNodes) ->
    randNums = []
    for i in [0.._dummyNodes.length-1]
      randNums.push(Math.floor(Math.random()*2**256))
    self.contract.methods.ringSign(_userSig, _prvKey, _dummyNodes, randNums).call().then(
      (_sig, _success) ->
        if _success
          sigJSON = JSON.stringify(_sig)
          return sigJSON
        return null
    )

  #User methods

  self.signUserMsg = (_uid) ->
    block = null
    web3.eth.getBlock("latest").then(
      (_block) ->
        msg = "#{_block.number}#{_block.hash}#{_uid}"
        block = _block
        _userSig = web3.eth.sign(web3.utils.keccak256(msg), web3.eth.defaultAccount)
    ).then(
      (_userSig) ->
        result =
          _blockNum: block.number
          _blockHash: block.hash
          _uid: _uid
          _userAddr: web3.eth.defaultAccount
          _userSig: _userSig
        return result
    )

  self.logProof = (_blockNum, _blockHash, _uid, _userAddr, _userSig, _ringSigJSON) ->
    self.contract.methods.logProof(_blockNum, _blockHash, _uid, _userAddr, _userSig, JSON.parse(_ringSigJSON)).send({from: web3.eth.defaultAccount})

  self.verifyProof = (_blockNum, _blockHash, _uid, _userAddr, _userSig, _ringSigJSON) ->
    self.contract.methods.verifyProof(_blockNum, _blockHash, _uid, _userAddr, _userSig, JSON.parse(_ringSigJSON)).call()

  return self

