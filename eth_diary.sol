// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;
pragma experimental ABIEncoderV2;

contract eth_diary {
    address public owner;
    uint256 public entry_count;
    string public index_cid;

    mapping(uint256 => string) public entries;
    mapping(uint256 => bool) public deleted;

    event entry(uint256 indexed id, string cid, uint8 entry_type);

    modifier only_owner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor() public {
        owner = msg.sender;
    }

    function post(string calldata cid, uint8 entry_type, string calldata new_index_cid) external only_owner {
        entries[entry_count] = cid;
        emit entry(entry_count, cid, entry_type);
        entry_count++;
        index_cid = new_index_cid;
    }

    function delete_entries(uint256[] calldata ids, string calldata new_index_cid) external only_owner {
        for (uint256 i = 0; i < ids.length; i++) {
            deleted[ids[i]] = true;
        }
        index_cid = new_index_cid;
    }

    function restore_entries(uint256[] calldata ids, string calldata new_index_cid) external only_owner {
        for (uint256 i = 0; i < ids.length; i++) {
            deleted[ids[i]] = false;
        }
        index_cid = new_index_cid;
    }

    function transfer_ownership(address new_owner) external only_owner {
        require(new_owner != address(0), "Invalid address");
        owner = new_owner;
    }

    function update_index(string calldata new_index_cid) external only_owner {
        index_cid = new_index_cid;
    }

    function get_entries(uint256 from, uint256 to) external view returns (string[] memory cids, bool[] memory is_deleted) {
        require(to > from, "Invalid range");
        uint256 len = to - from;
        cids = new string[](len);
        is_deleted = new bool[](len);
        for (uint256 i = 0; i < len; i++) {
            cids[i] = entries[from + i];
            is_deleted[i] = deleted[from + i];
        }
    }
}