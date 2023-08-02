// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Registrar is ERC721, Ownable, ReentrancyGuard {
    using Strings for uint256;

    struct Username {
        string name;
        uint256 registeredAt;
    }

    uint256 public usernameId;
    uint256 public fee;

    mapping(uint256 => Username) public usernames;
    mapping(string => uint256) public usernameToId;
    mapping(address => uint256) public addressToPrimaryUsername;
    mapping(address => uint256[]) public ownerUsernames;

    event UsernameRegistered(
        address indexed owner,
        string username,
        uint256 indexed tokenId,
        uint256 registeredAt
    );

    constructor(uint256 _initialFee) ERC721("Usernam3", "") {
        fee = _initialFee;
    }

    function setFee(uint256 _newFee) external onlyOwner {
        fee = _newFee;
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No balance to withdraw");

        payable(owner()).transfer(balance);
    }

    function setPrimaryUsername(uint256 _usernameId) public {
        require(
            _isApprovedOrOwner(msg.sender, _usernameId),
            "Caller is not owner nor approved"
        );
        addressToPrimaryUsername[msg.sender] = _usernameId;
    }

    function getPrimaryUsername(address owner) external view returns (uint256) {
        return addressToPrimaryUsername[owner];
    }

    function register(string memory _username) public payable nonReentrant {
        _username = _toLowerCase(_username);
        require(
            isValidUsername(_username),
            "Username should only contain letters and numbers"
        );
        require(usernameToId[_username] == 0, "Username already registered");
        require(msg.value >= fee, "Fee is not sufficient");

        usernameId++;
        usernames[usernameId] = Username(_username, block.timestamp);
        usernameToId[_username] = usernameId;

        _mint(msg.sender, usernameId);
        ownerUsernames[msg.sender].push(usernameId);

        emit UsernameRegistered(
            msg.sender,
            _username,
            usernameId,
            block.timestamp
        );
    }

    function getUsernamesByOwner(address owner)
        external
        view
        returns (uint256[] memory)
    {
        return ownerUsernames[owner];
    }

    function getOwnerOfUsername(string memory _username)
        public
        view
        returns (address)
    {
        uint256 tokenId = usernameToId[_username];
        return ownerOf(tokenId);
    }

    function getUsername(uint256 tokenId)
        external
        view
        returns (string memory)
    {
        return usernames[tokenId].name;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        Username memory username = usernames[tokenId];
        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name":"',
                        username.name,
                        '", "description":"Usernam3: ',
                        username.name,
                        '", "image":"',
                        'data:image/svg+xml;utf8,<svg xmlns=\\"http://www.w3.org/2000/svg\\" viewBox=\\"0 0 350 350\\"><style>.base { fill: white; font-family: sans-serif; font-size: 24px; }</style><rect width=\\"100%\\" height=\\"100%\\" fill=\\"%3B68FF\\"/><circle cx=\\"175\\" cy=\\"175\\" r=\\"100\\" fill=\\"%2355ABDD\\"/><text x=\\"50%\\" y=\\"50%\\" dy=\\"0.3em\\" class=\\"base\\" text-anchor=\\"middle\\">',
                        username.name,
                        '</text></svg>", "attributes":[{ "trait_type":"Registered on", "value":',
                        Strings.toString(username.registeredAt),
                        "}] }"
                    )
                )
            )
        );
        string memory output = string(
            abi.encodePacked("data:application/json;base64,", json)
        );

        return output;
    }

    function isValidUsername(string memory username)
        internal
        pure
        returns (bool)
    {
        bytes memory b = bytes(username);
        for (uint256 i; i < b.length; i++) {
            bytes1 char = b[i];
            if (
                !(char >= 0x30 && char <= 0x39) && //9-0
                !(char >= 0x61 && char <= 0x7A)
            )
                //a-z
                return false;
        }
        return true;
    }

    function _toLowerCase(string memory str)
        internal
        pure
        returns (string memory)
    {
        bytes memory bStr = bytes(str);
        bytes memory bLower = new bytes(bStr.length);
        for (uint256 i = 0; i < bStr.length; i++) {
            // Uppercase character...
            if ((uint8(bStr[i]) >= 65) && (uint8(bStr[i]) <= 90)) {
                // So we add 32 to it to make it lowercase
                bLower[i] = bytes1(uint8(bStr[i]) + 32);
            } else {
                bLower[i] = bStr[i];
            }
        }
        return string(bLower);
    }
}

library Base64 {
    bytes internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

        uint256 dataLen = data.length;
        uint256 encodeLen = 4 * ((dataLen + 2) / 3); // 3-byte clusters, rounded up

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodeLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, dataLen) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xFFFFFF)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(input, 0x3F))), 0xFF)
                )
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(dataLen, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodeLen)
        }

        return string(result);
    }
}
