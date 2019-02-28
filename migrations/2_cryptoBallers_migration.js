var CryptoBallers = artifacts.require("./CryptoBallers.sol");

module.exports = function(deployer) {
  deployer.deploy(CryptoBallers);
};
