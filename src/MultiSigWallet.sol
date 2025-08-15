// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract MultiSigWallet {
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

    event Deposit(address indexed sender, uint256 amount);
    event Submit(uint256 indexed txId);
    event Approve(address indexed owner, uint256 indexed txId);
    event Revoke(address indexed owner, uint256 indexed txId);
    event Execute(uint256 indexed txId);
    event Cancel(uint256 indexed txId);

    struct Transaction {
        address to;
        uint256 value;
        bytes data;
        bool executed;
        bool canceled;
    }

    mapping(address => bool) isOwner;
    address[] private owners;
    uint256 private immutable threshold;

    Transaction[] private transactions;
    mapping(uint256 => mapping(address => bool)) public approved;

    constructor(address[] memory _owners, uint256 _threshold) {
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
        if (_threshold > owners.length) {
            revert InvalidThreshold();
        }
        if (_threshold == 0) {
            revert InvalidThreshold();
        }
        threshold = _threshold;
    }

    modifier onlyOwner() {
        if (!isOwner[msg.sender]) {
            revert NotAnOwner();
        }
        _;
    }

    modifier txExists(uint256 _txId) {
        if (_txId >= transactions.length) {
            revert TransactionDoesNotExist();
        }
        _;
    }

    modifier notApproved(uint256 _txId) {
        if (approved[_txId][msg.sender] == true) {
            revert AlreadyApproved();
        }
        _;
    }

    modifier isApproved(uint256 _txId) {
        if (approved[_txId][msg.sender] == false) {
            revert NotApproved();
        }
        _;
    }

    modifier notExecuted(uint256 _txId) {
        if (transactions[_txId].executed) {
            revert AlreadyExecuted();
        }
        _;
    }

    modifier notCanceled(uint256 _txId) {
        if (transactions[_txId].canceled) {
            revert AlreadyCanceled();
        }
        _;
    }

    /*//////////////////////////////////////////////////////////////
                            MAIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    function submit(address _to, uint256 _value, bytes calldata _data) external onlyOwner {
        transactions.push(Transaction({to: _to, value: _value, data: _data, executed: false, canceled: false}));
        emit Submit(transactions.length - 1);
    }

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

    function cancel(uint256 _txId) external onlyOwner txExists(_txId) notExecuted(_txId) notCanceled(_txId) {
        if (_hasEnoughApprovals(_txId)) {
            revert AlreadyApproved();
        }

        transactions[_txId].canceled = true;
        emit Cancel(_txId);
    }

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

    function _hasEnoughApprovals(uint256 _txId) internal view returns (bool) {
        uint256 approveGiven = 0;
        for (uint256 i = 0; i < owners.length; i++) {
            if (approved[_txId][owners[i]]) {
                approveGiven++;
            }
        }
        return approveGiven >= threshold;
    }

    function _requireEnoughApprovals(uint256 _txId) internal view {
        if (!_hasEnoughApprovals(_txId)) {
            revert NotApproved();
        }
    }

    /*//////////////////////////////////////////////////////////////
                            GETTER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function getWalletBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function getTransactionById(uint256 _txId) external view returns (Transaction memory) {
        return transactions[_txId];
    }

    function getOwners() external view returns (address[] memory) {
        return owners;
    }

    function addressIsOwner(address _owner) external view returns (bool) {
        return isOwner[_owner];
    }

    function getThreshold() external view returns (uint256) {
        return threshold;
    }

    function getBalance(address user) external view returns (uint256) {
        return user.balance;
    }

    function getTransactionCount() external view returns (uint256) {
        return transactions.length;
    }

    function getOwnerByIndex(uint256 index) external view returns (address) {
        if (index >= owners.length) {
            revert InvalidAddress();
        }
        return owners[index];
    }
}
