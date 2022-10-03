// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

contract MainLock is OwnableUpgradeable, IERC1155, ERC1155Holder {
    ERC1155 public token;

    mapping(address => mapping(uint256 => uint256)) public override balanceOf;

    mapping(uint256 => BatchLock) startTimeToBatchLock;
    uint256[] startTimes;
    mapping(address => mapping(uint256 => uint256)) adrIdAmount;
    mapping(address => uint256[]) adrToIds;

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

    function initialize(address _owner, address _token) public initializer {
        __Ownable_init();
        transferOwnership(_owner);
        token = ERC1155(_token);
    }

    struct BatchLock {
        uint256 startDate;
        address[] assetAddresses;
        uint256[] lockingPeriods;
        uint256[] ids;
        uint256[] amounts;
        address[] receivers;
    }

    function startLocking(
        address[] memory _assetAddresses,
        uint256[] memory _lockingPeriods,
        uint256[] memory _ids,
        uint256[] memory _amounts,
        address[] memory _receivers
    ) external onlyOwner {
        uint256 time = block.timestamp;
        startTimeToBatchLock[time].startDate = time;
        startTimeToBatchLock[time].assetAddresses = _assetAddresses;
        startTimeToBatchLock[time].lockingPeriods = _lockingPeriods;
        startTimeToBatchLock[time].ids = _ids;
        startTimeToBatchLock[time].amounts = _amounts;
        startTimeToBatchLock[time].receivers = _receivers;
        startTimes.push(time);
        for (uint256 i; i < _amounts.length; i++) {
            IERC1155(address(token)).safeTransferFrom(
                _assetAddresses[i],
                address(this),
                _ids[i],
                _amounts[i],
                ""
            );
            adrToIds[startTimeToBatchLock[time].receivers[i]].push(
                startTimeToBatchLock[time].ids[i]
            ); //careful
        }
    }

    function withdraww(uint256 amount, uint256 id) external {
        uint256 restAmount = amount;

        for (uint256 i; i < startTimes.length; i++) {
            for (
                uint256 j;
                j < startTimeToBatchLock[startTimes[i]].receivers.length;
                j++
            ) {
                if (
                    startTimeToBatchLock[startTimes[i]].receivers[j] ==
                    msg.sender
                ) {
                    if (
                        startTimeToBatchLock[startTimes[i]].lockingPeriods[j] +
                            startTimeToBatchLock[startTimes[i]].startDate <=
                        block.timestamp
                    ) {
                        if (startTimeToBatchLock[startTimes[i]].ids[j] == id) {
                            if (
                                startTimeToBatchLock[startTimes[i]].amounts[
                                    j
                                ] >= restAmount
                            ) {
                                startTimeToBatchLock[startTimes[i]].amounts[
                                        j
                                    ] -= restAmount;
                                restAmount = 0;
                                i = startTimes.length;
                                break;
                            } else {
                                restAmount =
                                    amount -
                                    startTimeToBatchLock[startTimes[i]].amounts[
                                        j
                                    ];

                                startTimeToBatchLock[startTimes[i]].amounts[
                                        j
                                    ] = 0;
                            }
                        }
                    }
                }
            }
        }
        if (restAmount == 0) {
            token.setApprovalForAll(msg.sender, true);
            token.safeTransferFrom(address(this), msg.sender, id, amount, "");
        }
    }

    /*function startBatchLocking(
        address[] memory _assetAddresses,
        uint256[] memory _lockingPeriods,
        uint256[][] memory _ids,
        uint256[][] memory _amounts,
        address[] memory _receivers
    ) external onlyOwner {
        uint256 time = block.timestamp;
        startTimeToBatchLock[time].startDate = time;
        startTimeToBatchLock[time].assetAddresses = _assetAddresses;
        startTimeToBatchLock[time].lockingPeriods = _lockingPeriods;
        startTimeToBatchLock[time].ids = _ids;
        startTimeToBatchLock[time].amounts = _amounts;
        startTimeToBatchLock[time].receivers = _receivers;
        startTimes.push(time);
        for (uint256 i; i < _receivers.length; i++) {
            
            IERC1155(address(token)).safeBatchTransferFrom(
                _assetAddresses[i],
                address(this),
                _ids[i],
                _amounts[i],
                ""
            );
        
            
            
        }
    }*/

    /*function withdraww(uint256 id, uint256 amount) external {
        uint256 restAmount = amount;

        for (uint256 i; i < startTimes.length; i++) {
            for (
                uint256 j;
                j < startTimeToBatchLock[startTimes[i]].receivers.length;
                j++
            ) {
                if (startTimeToBatchLock[startTimes[i]].receivers[j] == msg.sender) {
                    if (
                        startTimeToBatchLock[startTimes[i]].lockingPeriods[j] +
                            startTimeToBatchLock[startTimes[i]].startDate <=
                        block.timestamp
                    ) {
                        for(uint l; l < startTimeToBatchLock[startTimes[i]].ids[j].length; l++){
                            if(
                                startTimeToBatchLock[startTimes[i]].ids[j][l] == id
                            ){
                                

                                if (                         
                                    startTimeToBatchLock[startTimes[i]].amounts[j][l] >= restAmount
                                ) {
                                    startTimeToBatchLock[startTimes[i]].amounts[j][l] -= restAmount;
                                    restAmount = 0;
                                    i = startTimes.length;
                                    break;
                                } else {
                                    restAmount = amount - startTimeToBatchLock[startTimes[i]].amounts[j][l];

                                    startTimeToBatchLock[startTimes[i]].amounts[j][l] = 0;
                                }
                            }
                        }
                        
                    }
                }
            }
        }
        if (restAmount == 0) {
            
            token.safeTransferFrom(address(this), msg.sender, id, amount, "");
            
            token.setApprovalForAll(msg.sender, true);
        }
    }*/

    function userAvailableAmount(uint256 id) external view returns (uint256) {
        uint256 amount;

        for (uint256 i; i < startTimes.length; i++) {
            for (
                uint256 j;
                j < startTimeToBatchLock[startTimes[i]].receivers.length;
                j++
            ) {
                if (
                    startTimeToBatchLock[startTimes[i]].receivers[j] ==
                    msg.sender
                ) {
                    if (
                        startTimeToBatchLock[startTimes[i]].lockingPeriods[j] +
                            startTimeToBatchLock[startTimes[i]].startDate <=
                        block.timestamp
                    ) {
                        if (startTimeToBatchLock[startTimes[i]].ids[j] == id) {
                            amount += startTimeToBatchLock[startTimes[i]]
                                .amounts[j];
                        }
                    }
                }
            }
        }

        return (amount);
    }

    function checkId(uint256[] memory ids, uint256 id)
        internal
        view
        returns (bool)
    {
        for (uint256 i; i < ids.length; i++) {
            if (ids[i] == id) {
                return true;
            }
        }
        return false;
    }

    function lockedAmount(uint256 id) external view returns (uint256) {
        uint256 amount;

        for (uint256 i; i < startTimes.length; i++) {
            for (
                uint256 j;
                j < startTimeToBatchLock[startTimes[i]].receivers.length;
                j++
            ) {
                if (
                    startTimeToBatchLock[startTimes[i]].receivers[j] ==
                    msg.sender
                ) {
                    if (startTimeToBatchLock[startTimes[i]].ids[j] == id) {
                        amount += startTimeToBatchLock[startTimes[i]].amounts[
                            j
                        ];
                    }
                }
            }
        }

        return (amount);
    }

    function allLocks() external view returns (uint256[] memory) {
        return startTimes;
    }

    function assetAddressList(uint256 startTime)
        external
        view
        returns (address[] memory)
    {
        return startTimeToBatchLock[startTime].assetAddresses;
    }

    function lockingInfo(uint256 startTime)
        external
        view
        returns (uint256[] memory)
    {
        return startTimeToBatchLock[startTime].lockingPeriods;
    }

    function idAmountList(uint256 startTime)
        external
        view
        returns (uint256[] memory)
    {
        return (startTimeToBatchLock[startTime].ids);
    }

    function idsOfUser() external view returns (uint256[] memory) {
        return adrToIds[msg.sender];
    }

    function walletList(uint256 startTime)
        external
        view
        returns (address[] memory)
    {
        return startTimeToBatchLock[startTime].receivers;
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */

    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(
            accounts.length == ids.length,
            "ERC1155: accounts and ids length mismatch"
        );

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf[accounts[i]][ids[i]];
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
    {
        revert NotSupported();
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        revert NotSupported();
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        revert NotSupported();
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        revert NotSupported();
    }
}
