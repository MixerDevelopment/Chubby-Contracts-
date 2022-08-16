// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MainLock is OwnableUpgradeable, IERC20 {
    ERC20 public token;


    uint256 public override totalSupply;
    mapping(address => uint256) public override balanceOf;
    mapping(uint256 => Lock) startTimeToLock;
    uint256[] startTimes;

    /// Withdraw amount exceeds sender's balance of the locked token
    error ExceedsBalance();
    /// Deposit is not possible anymore because the deposit period is over
    error DepositPeriodOver();
    /// Withdraw is not possible because the lock period is not over yet
    error LockPeriodOngoing();
    /// Could not transfer the designated ERC20 token
    error TransferFailed();
    /// ERC-20 function is not supported
    error NotSupported();

    function initialize(
        address _owner,
        address _token
    ) public initializer {
        __Ownable_init();
        transferOwnership(_owner);
        token = ERC20(_token);
        totalSupply = 0;
    }

    struct Lock {
        uint256 startDate;
        address[] assetAddresses;
        uint256[] lockingPeriods;
        uint256[] amounts;
        address[] receivers;
    }

    function startLocking(
        address[] memory _assetAddresses,
        uint256[] memory _lockingPeriods,
        uint256[] memory _amounts,
        address[] memory _receivers
    ) external onlyOwner {
        uint time = block.timestamp;
        startTimeToLock[time].startDate = time;
        startTimeToLock[time].assetAddresses = _assetAddresses;
        startTimeToLock[time].lockingPeriods = _lockingPeriods;
        startTimeToLock[time].amounts = _amounts;
        startTimeToLock[time].receivers = _receivers;
        startTimes.push(time);
        for (uint256 i; i < _amounts.length; i++) {
            totalSupply += _amounts[i];
           
            IERC20(address(token)).transferFrom(_assetAddresses[i], address(this), _amounts[i]);
            
        }
    }

    function withdraww(uint256 amount) external {
        uint256 restAmount = amount;

        for (uint256 i; i < startTimes.length; i++) {
            for (
                uint256 j;
                j < startTimeToLock[startTimes[i]].receivers.length;
                j++
            ) {
                if (startTimeToLock[startTimes[i]].receivers[j] == msg.sender) {
                    if (
                        startTimeToLock[startTimes[i]].lockingPeriods[j] +
                            startTimeToLock[startTimes[i]].startDate <=
                        block.timestamp
                    ) {
                        if (
                            startTimeToLock[startTimes[i]].amounts[j] >=
                            restAmount
                        ) {
                            startTimeToLock[startTimes[i]].amounts[
                                    j
                                ] -= restAmount;
                            restAmount = 0;
                            i = startTimes.length;
                            break;
                        } else {
                            restAmount =
                                amount -
                                startTimeToLock[startTimes[i]].amounts[j];

                            startTimeToLock[startTimes[i]].amounts[j] = 0;
                        }
                    }
                }
            }
        }
        if (restAmount == 0) {
            token.transfer(msg.sender, amount);
            totalSupply -= amount;
            token.approve(msg.sender, amount);
        }
    }

    function allLocks() external view returns (uint256[] memory) {
        return startTimes;
    }

    function assetAddressList(uint256 startTime)
        external
        view
        returns (address[] memory)
    {
        return startTimeToLock[startTime].assetAddresses;
    }

    function lockingInfo(uint256 startTime)
        external
        view
        returns (uint256[] memory)
    {
        return startTimeToLock[startTime].lockingPeriods;
    }

    function amountList(uint256 startTime)
        external
        view
        returns (uint256[] memory)
    {
        return startTimeToLock[startTime].amounts;
    }

    function walletList(uint256 startTime)
        external
        view
        returns (address[] memory)
    {
        return startTimeToLock[startTime].receivers;
    }

    /// @dev Lock claim tokens are non-transferrable: ERC-20 transfer is not supported
    function transfer(address, uint256) external pure override returns (bool) {
        revert NotSupported();
    }

    /// @dev Lock claim tokens are non-transferrable: ERC-20 allowance is not supported
    function allowance(address, address)
        external
        pure
        override
        returns (uint256)
    {
        revert NotSupported();
    }

    /// @dev Lock claim tokens are non-transferrable: ERC-20 approve is not supported
    function approve(address, uint256) external pure override returns (bool) {
        revert NotSupported();
    }

    /// @dev Lock claim tokens are non-transferrable: ERC-20 transferFrom is not supported
    function transferFrom(
        address,
        address,
        uint256
    ) external pure override returns (bool) {
        revert NotSupported();
    }
}
