// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
//q why are we using this?
interface ICurrencyManager {
  function addCurrency(address currency) external;

  function removeCurrency(address currency) external;

  function isCurrencyWhitelisted(address currency) external view returns (bool);

  function viewWhitelistedCurrencies(
    uint256 cursor,
    uint256 size
  ) external view returns (address[] memory, uint256);

  function viewCountWhitelistedCurrencies() external view returns (uint256);
}
