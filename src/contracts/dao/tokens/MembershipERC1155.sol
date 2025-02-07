// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../interfaces/IERC1155Mintable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/// @title Membership ERC1155 Token
/// @notice This contract allows the creation and management of a DAO membership NFT that supports profit sharing.
contract MembershipERC1155 is ERC1155Upgradeable, AccessControlUpgradeable, IMembershipERC1155 {
    using SafeERC20 for IERC20;
    using Strings for uint256;

    bytes32 public constant OWP_FACTORY_ROLE = keccak256("OWP_FACTORY_ROLE");
    bytes32 public constant DAO_CREATOR = keccak256("DAO_CREATOR");

    string private _name;
    string private _symbol;
    address public creator;
    address public currency;
    uint256 public totalSupply;

    uint256 public totalProfit;
    mapping(address => uint256) internal lastProfit;
    mapping(address => uint256) internal savedProfit;

    uint256 internal constant ACCURACY = 1e30;

    event Claim(address indexed account, uint256 amount);
    event Profit(uint256 amount);

    constructor(){
        _disableInitializers();
    }

 //@audit-info missing zero check address
    function initialize(
        string memory name_,
        string memory symbol_,
        string memory uri_,
        address creator_,
        address currency_
    ) external initializer {
        _name = name_;
        _symbol = symbol_;
        creator = creator_;
        currency = currency_;
        _setURI(uri_);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(DAO_CREATOR, creator_);
        _grantRole(OWP_FACTORY_ROLE, msg.sender);
    }

    /// @notice Mint a new token
    /// @param to The address to mint tokens to
    /// @param tokenId The token ID to mint
    /// @param amount The amount of tokens to mint

    //@audit-info missing zero check address
    function mint(address to, uint256 tokenId, uint256 amount) external override onlyRole(OWP_FACTORY_ROLE) {
        totalSupply += amount * 2 ** (6 - tokenId); // Update total supply with weight
        _mint(to, tokenId, amount, "");
    }

    /// @notice Burn tokens
    /// @param from The address from which tokens will be burned
    /// @param tokenId The token ID to burn
    /// @param amount The amount of tokens to burn
    //@audit-info missing zero check address
    function burn(address from, uint256 tokenId, uint256 amount) external onlyRole(OWP_FACTORY_ROLE) {
        burn_(from, tokenId, amount);
    }

    function burn_(address from, uint256 tokenId, uint256 amount) internal {
        totalSupply -= amount * 2 ** (6 - tokenId); // Update total supply with weight
        _burn(from, tokenId, amount);
    }

    /// @notice Burn all tokens of a single user
    /// @param from The address from which tokens will be burned
    function burnBatch(address from) public onlyRole(OWP_FACTORY_ROLE) {
        for (uint256 i = 0; i < 7; ++i) {
            uint256 amount = balanceOf(from, i);
            if (amount > 0) {
                burn_(from, i, amount);
            }
        }
    }

    /// @notice Burn all tokens of multiple users
    /// @param froms The addresses from which tokens will be burned
    function burnBatchMultiple(address[] memory froms)
        public
        onlyRole(OWP_FACTORY_ROLE)
    {
        for(uint256 j = 0; j < froms.length; ++j){
            for(uint256 i = 0; i < 7; ++i){
                uint256 amount = balanceOf(froms[j], i);
                if (amount > 0) {
                    burn_(froms[j], i, amount);
                }
            }
        }        
    }

    /// @notice Set a new URI for all token types
    /// @param newURI The new URI to set
    function setURI(string memory newURI) external onlyRole(DAO_CREATOR) {
        _setURI(newURI);
    }

    /// @notice Get the token name
    /// @return The name of the token
    function name() public view returns (string memory) {
        return _name;
    }

    function uri(uint256 tokenId) public view virtual override returns (string memory) {
        return string(abi.encodePacked(
            super.uri(tokenId),
            Strings.toHexString(uint256(uint160(address(this))), 20),
            "/",
            Strings.toString(tokenId)
        ));
    }

    /// @notice Get the token symbol
    /// @return The symbol of the token
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /// @notice Checks if the contract supports an interface
    /// @param interfaceId The interface identifier, as specified in ERC-165
    /// @return True if the contract supports the interface
     // @audit-gas using `public` visibility is expensive
    function supportsInterface(bytes4 interfaceId)
        public view override(ERC1155Upgradeable, AccessControlUpgradeable) returns (bool) {
        return
            interfaceId == type(IMembershipERC1155).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /// @notice Claim profits accumulated from the profit pool
    /// @return profit The amount of profit claimed

    // @audit-gas require statement will cause alot of gas
    // @audit-info possible re-entrancy attack
    function claimProfit() external returns (uint256 profit) {
        profit = saveProfit(msg.sender);
        require(profit > 0, "No profit available");
        savedProfit[msg.sender] = 0;
        IERC20(currency).safeTransfer(msg.sender, profit);
        emit Claim(msg.sender, profit);
    }

    /// @notice View profit for an account
    /// @param account The account to query
    /// @return The total profit amount for the account
    function profitOf(address account) external view returns (uint256) {
        return savedProfit[account] + getUnsaved(account);
    }

    /// @notice Calculates unsaved profits for an account
    /// @param account The account to query
    /// @return profit The unsaved profit amount
    function getUnsaved(address account) internal view returns (uint256 profit) {
        return ((totalProfit - lastProfit[account]) * shareOf(account)) / ACCURACY;
    }

    /// @notice Calculates the share of total profits for an account
    /// @param account The account to query
    /// @return The weighted share of the account
    //@follow-up
    //@audit-info magic numbers
    function shareOf(address account) public view returns (uint256) {
        return (balanceOf(account, 0) * 64) +
               (balanceOf(account, 1) * 32) +
               (balanceOf(account, 2) * 16) +
               (balanceOf(account, 3) * 8) +
               (balanceOf(account, 4) * 4) +
               (balanceOf(account, 5) * 2) +
               balanceOf(account, 6);
    }

    /// @notice Updates profit tracking after a claim
    /// @param account The account updating profits for
    /// @return profit The updated saved profit
    //@follow-up
    function saveProfit(address account) internal returns (uint256 profit) {
        uint256 unsaved = getUnsaved(account);
        lastProfit[account] = totalProfit;
        profit = savedProfit[account] + unsaved;
        savedProfit[account] = profit;
    }

    /// @notice Distributes profits to token holders
    /// @param amount The amount of currency to distribute
    @follow-up
    function sendProfit(uint256 amount) external {
        uint256 _totalSupply = totalSupply;
        if (_totalSupply > 0) {
            totalProfit += (amount * ACCURACY) / _totalSupply;
            IERC20(currency).safeTransferFrom(msg.sender, address(this), amount);
            emit Profit(amount);
        } else {
            IERC20(currency).safeTransferFrom(msg.sender, creator, amount); // Redirect profit to creator if no supply
        }
    }

    // Override transfers to update savedProfit (claimed rewards)
    function _update(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual override(ERC1155Upgradeable) {
        if (from != address(0)) saveProfit(from);
        if (to != address(0)) saveProfit(to);
        super._update(from, to, ids, amounts);
    }

    /// @notice Performs an external call to another contract
    /// @param contractAddress The address of the external contract
    /// @param data The calldata to be sent
    /// @return result The bytes result of the external call

    //q why is the contract calling external Contract
    // @audit-info The function missing a zero address check
    function callExternalContract(address contractAddress, bytes memory data) external payable onlyRole(OWP_FACTORY_ROLE) returns (bytes memory ) {
        (bool success, bytes memory returndata) = contractAddress.call{value: msg.value}(data);
        require(success, "External call failed");
        return returndata;
    }
}
