const Wolin = artifacts.require("Wolin");

module.exports = function (deployer) {
  deployer.deploy(
    Wolin,
    "0x652B2937Efd0B5beA1c8d54293FC1289672AFC6b",
    "0xc153eeAD19e0DBbDb3462Dcc2B703cC6D738A37c",
    "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D",
    //"0x64dC205C30A1ad51D34072Df33981920B7B2103C",
    "25"
  );
};
