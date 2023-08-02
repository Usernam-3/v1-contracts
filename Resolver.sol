// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./Registrar.sol";

contract Resolver {
    Registrar public registrar;

    constructor(address _registrar) {
        registrar = Registrar(_registrar);
    }

    function resolveToUsername(address _owner) public view returns (string memory) {
        uint256 tokenId = registrar.getPrimaryUsername(_owner);
        return registrar.getUsername(tokenId);
    }

    function resolveToAddress(string memory _username) public view returns (address) {
        return registrar.getOwnerOfUsername(_username);
    }
}
