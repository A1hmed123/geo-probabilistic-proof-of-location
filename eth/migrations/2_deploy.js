var PPoL = artifacts.require("PPoL");
var ECRecovery = artifacts.require("ECRecovery")

module.exports = function(deployer) {
  deployer.deploy(ECRecovery).then(
    () => {
      deployer.link(ECRecovery, [PPoL]);
      deployer.deploy(PPoL);
    }
  );
};
