// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title MultiSigWallet
 * @author Your Name
 * @notice A multi-signature wallet that requires multiple owner approvals to execute transactions
 * @dev Implements a secure multi-signature wallet with configurable threshold
 */
contract MultiSigWallet {
    /*//////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/

    error InvalidAddress();
    error InvalidThreshold();
    error IsAlreadyOwner();
    error NotAnOwner();
    error TransactionDoesNotExist();
    error AlreadyApproved();
    error AlreadyExecuted();
    error NotApproved();
    error TransactionFailed();
    error AlreadyCanceled();

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Emitted when Ether is deposited into the wallet
     * @param sender The address that sent the Ether
     * @param amount The amount of Ether deposited in wei
     */
    event Deposit(address indexed sender, uint256 amount);

    /**
     * @notice Emitted when a new transaction is submitted
     * @param txId The unique identifier of the transaction
     */
    event Submit(uint256 indexed txId);

    /**
     * @notice Emitted when an owner approves a transaction
     * @param owner The address of the owner who approved
     * @param txId The unique identifier of the transaction
     */
    event Approve(address indexed owner, uint256 indexed txId);

    /**
     * @notice Emitted when an owner revokes their approval
     * @param owner The address of the owner who revoked approval
     * @param txId The unique identifier of the transaction
     */
    event Revoke(address indexed owner, uint256 indexed txId);

    /**
     * @notice Emitted when a transaction is executed
     * @param txId The unique identifier of the executed transaction
     */
    event Execute(uint256 indexed txId);

    /**
     * @notice Emitted when a transaction is canceled
     * @param txId The unique identifier of the canceled transaction
     */
    event Cancel(uint256 indexed txId);

    /*//////////////////////////////////////////////////////////////
                                STRUCTS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Structure representing a multi-sig transaction
     * @param to The destination address for the transaction
     * @param value The amount of Ether to send in wei
     * @param data The calldata to be executed
     * @param executed Whether the transaction has been executed
     * @param canceled Whether the transaction has been canceled
     */
    struct Transaction {
        address to;
        uint256 value;
        bytes data;
        bool executed;
        bool canceled;
    }

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    /// @notice Mapping to check if an address is an owner
    mapping(address => bool) public isOwner;

    /// @notice Array of wallet owners
    address[] private owners;

    /// @notice The minimum number of approvals required to execute a transaction
    uint256 public immutable threshold;

    /// @notice Array of all transactions
    Transaction[] private transactions;

    /// @notice Mapping from transaction ID to owner to approval status
    mapping(uint256 => mapping(address => bool)) public approved;

    /*//////////////////////////////////////////////////////////////
                              MODIFIERS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Restricts function access to wallet owners only
     */
    modifier onlyOwner() {
        if (!isOwner[msg.sender]) {
            revert NotAnOwner();
        }
        _;
    }

    /**
     * @notice Ensures the transaction exists
     * @param _txId The transaction ID to check
     */
    modifier txExists(uint256 _txId) {
        if (_txId >= transactions.length) {
            revert TransactionDoesNotExist();
        }
        _;
    }

    /**
     * @notice Ensures the caller hasn't already approved the transaction
     * @param _txId The transaction ID to check
     */
    modifier notApproved(uint256 _txId) {
        if (approved[_txId][msg.sender]) {
            revert AlreadyApproved();
        }
        _;
    }

    /**
     * @notice Ensures the caller has approved the transaction
     * @param _txId The transaction ID to check
     */
    modifier isApproved(uint256 _txId) {
        if (!approved[_txId][msg.sender]) {
            revert NotApproved();
        }
        _;
    }

    /**
     * @notice Ensures the transaction hasn't been executed
     * @param _txId The transaction ID to check
     */
    modifier notExecuted(uint256 _txId) {
        if (transactions[_txId].executed) {
            revert AlreadyExecuted();
        }
        _;
    }

    /**
     * @notice Ensures the transaction hasn't been canceled
     * @param _txId The transaction ID to check
     */
    modifier notCanceled(uint256 _txId) {
        if (transactions[_txId].canceled) {
            revert AlreadyCanceled();
        }
        _;
    }

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Creates a new multi-signature wallet
     * @param _owners Array of owner addresses
     * @param _threshold Minimum number of approvals required for execution
     * @dev Validates owners and threshold, ensures no duplicate owners
     */
    constructor(address[] memory _owners, uint256 _threshold) {
        if (_owners.length == 0) {
            revert InvalidAddress();
        }

        for (uint256 i = 0; i < _owners.length; i++) {
            address owner = _owners[i];
            if (owner == address(0)) {
                revert InvalidAddress();
            }
            if (isOwner[owner]) {
                revert IsAlreadyOwner();
            }

            isOwner[owner] = true;
            owners.push(owner);
        }

        if (_threshold == 0 || _threshold > owners.length) {
            revert InvalidThreshold();
        }

        threshold = _threshold;
    }

    /*//////////////////////////////////////////////////////////////
                            MAIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Allows the contract to receive Ether
     * @dev Emits a Deposit event when Ether is received
     */
    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    /**
     * @notice Submits a new transaction for approval
     * @param _to The destination address
     * @param _value The amount of Ether to send in wei
     * @param _data The calldata for the transaction
     * @dev Only owners can submit transactions
     */
    function submit(address _to, uint256 _value, bytes calldata _data) external onlyOwner {
        transactions.push(Transaction({to: _to, value: _value, data: _data, executed: false, canceled: false}));
        emit Submit(transactions.length - 1);
    }

    /**
     * @notice Approves a pending transaction
     * @param _txId The ID of the transaction to approve
     * @dev Only owners can approve, and only once per transaction
     */
    function approve(uint256 _txId)
        external
        onlyOwner
        txExists(_txId)
        notApproved(_txId)
        notExecuted(_txId)
        notCanceled(_txId)
    {
        approved[_txId][msg.sender] = true;
        emit Approve(msg.sender, _txId);
    }

    /**
     * @notice Revokes approval for a transaction
     * @param _txId The ID of the transaction to revoke approval for
     * @dev Can only revoke if transaction doesn't have enough approvals to execute
     */
    function revoke(uint256 _txId)
        external
        onlyOwner
        txExists(_txId)
        notExecuted(_txId)
        notCanceled(_txId)
        isApproved(_txId)
    {
        if (_hasEnoughApprovals(_txId)) {
            revert AlreadyApproved();
        }

        approved[_txId][msg.sender] = false;
        emit Revoke(msg.sender, _txId);
    }

    /**
     * @notice Cancels a pending transaction
     * @param _txId The ID of the transaction to cancel
     * @dev Can only cancel if transaction doesn't have enough approvals
     */
    function cancel(uint256 _txId) external onlyOwner txExists(_txId) notExecuted(_txId) notCanceled(_txId) {
        if (_hasEnoughApprovals(_txId)) {
            revert AlreadyApproved();
        }

        transactions[_txId].canceled = true;
        emit Cancel(_txId);
    }

    /**
     * @notice Executes a transaction that has enough approvals
     * @param _txId The ID of the transaction to execute
     * @dev Uses checks-effects-interactions pattern for security
     */
    function execute(uint256 _txId) external onlyOwner txExists(_txId) notExecuted(_txId) notCanceled(_txId) {
        // Checks
        _requireEnoughApprovals(_txId);

        // Effects
        Transaction storage transaction = transactions[_txId];
        transaction.executed = true;

        // Interactions
        (bool success,) = transaction.to.call{value: transaction.value}(transaction.data);
        if (!success) {
            revert TransactionFailed();
        }

        emit Execute(_txId);
    }

    /*//////////////////////////////////////////////////////////////
                            INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Checks if a transaction has enough approvals
     * @param _txId The transaction ID to check
     * @return bool True if transaction has enough approvals
     */
    function _hasEnoughApprovals(uint256 _txId) internal view returns (bool) {
        uint256 approveGiven = 0;
        for (uint256 i = 0; i < owners.length; i++) {
            if (approved[_txId][owners[i]]) {
                approveGiven++;
            }
        }
        return approveGiven >= threshold;
    }

    /**
     * @notice Requires that a transaction has enough approvals
     * @param _txId The transaction ID to check
     * @dev Reverts with NotApproved if insufficient approvals
     */
    function _requireEnoughApprovals(uint256 _txId) internal view {
        if (!_hasEnoughApprovals(_txId)) {
            revert NotApproved();
        }
    }

    /*//////////////////////////////////////////////////////////////
                            GETTER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Returns the current balance of the wallet
     * @return uint256 The balance in wei
     */
    function getWalletBalance() external view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @notice Returns transaction details by ID
     * @param _txId The transaction ID
     * @return Transaction The transaction struct
     */
    function getTransactionById(uint256 _txId) external view returns (Transaction memory) {
        return transactions[_txId];
    }

    /**
     * @notice Returns all wallet owners
     * @return address[] Array of owner addresses
     */
    function getOwners() external view returns (address[] memory) {
        return owners;
    }

    /**
     * @notice Checks if an address is an owner
     * @param _owner The address to check
     * @return bool True if address is an owner
     */
    function addressIsOwner(address _owner) external view returns (bool) {
        return isOwner[_owner];
    }

    /**
     * @notice Returns the approval threshold
     * @return uint256 The minimum number of approvals required
     */
    function getThreshold() external view returns (uint256) {
        return threshold;
    }

    /**
     * @notice Returns the balance of any address
     * @param user The address to check balance for
     * @return uint256 The balance in wei
     */
    function getBalance(address user) external view returns (uint256) {
        return user.balance;
    }

    /**
     * @notice Returns the total number of transactions
     * @return uint256 The transaction count
     */
    function getTransactionCount() external view returns (uint256) {
        return transactions.length;
    }

    /**
     * @notice Returns owner address by index
     * @param index The index in the owners array
     * @return address The owner address
     * @dev Reverts if index is out of bounds
     */
    function getOwnerByIndex(uint256 index) external view returns (address) {
        if (index >= owners.length) {
            revert InvalidAddress();
        }
        return owners[index];
    }
}
