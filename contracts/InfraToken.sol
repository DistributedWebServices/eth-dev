pragma solidity ^0.4.4;

// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/issues/20
contract ERC20Interface {
    // Get the total token supply
    function totalSupply() constant returns (uint256 totalSupply);
 
    // Get the account balance of another account with address _owner
    function balanceOf(address _owner) constant returns (uint256 balance);
 
    // Send _value amount of tokens to address _to
    function transfer(address _to, uint256 _value) returns (bool success);
 
    // Send _value amount of tokens from address _from to address _to
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
 
    // Allow _spender to withdraw from your account, multiple times, up to the _value amount.
    // If this function is called again it overwrites the current allowance with _value.
    // this function is required for some DEX functionality
    function approve(address _spender, uint256 _value) returns (bool success);
 
    // Returns the amount which _spender is still allowed to withdraw from _owner
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);
 
    // Triggered when tokens are transferred.
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
 
    // Triggered whenever approve(address _spender, uint256 _value) is called.
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}
 
contract InfraToken is ERC20Interface {
    string public constant symbol = "INFR";
    string public constant name = "Infrastructure TOken";
    uint8 public constant decimals = 18;
    uint256 _ownerInitialAmount = 1000000;
    uint256 _totalSupply = _ownerInitialAmount;
    uint256 _nextAvailableContractId = 0;

    // Owner of this contract
    address public owner;

    // Balances for each account
    mapping(address => uint256) balances;

    // Owner of account approves the transfer of an amount to another account
    mapping(address => mapping (address => uint256)) allowed;

    // Address of valid Service Contracts
    mapping(address => bool) serviceContracts;

    // How much is currently left in escrow for a service contract
    mapping(address => uint256) openContractsEscrow;

    // Get all contracts for an address of seller/buyer
    mapping(address => unit256[]) buyerContracts;
    mapping(address => unit256[]) sellerContracts;

    modifier onlyOwner() {
        require(msg.sender == owner); 
        _;
    }

    function InfraToken() {
        owner = msg.sender;
        balances[owner] = _ownerInitialAmount;
    }

    function addServiceContract(address _serviceContract) onlyOwner {
        serviceContracts[_serviceContract] = true;
    }

    function removeServiceContract(address _serviceContract) onlyOwner {
        serviceContracts[_serviceContract] = false;
    }

    function totalSupply() constant returns (uint256 totalSupply) {
        totalSupply = _totalSupply;
    }
 
    // What is the balance of a particular account?
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }
 
    // Transfer the balance from owner's account to another account
    function transfer(address _to, uint256 _amount) returns (bool success) {
        if (balances[msg.sender] >= _amount 
            && _amount > 0
            && balances[_to] + _amount > balances[_to]) {
            balances[msg.sender] -= _amount;
            balances[_to] += _amount;
            Transfer(msg.sender, _to, _amount);
            return true;
        } else {
            return false;
        }
    }
 
    // Send _value amount of tokens from address _from to address _to
    // The transferFrom method is used for a withdraw workflow, allowing contracts to send
    // tokens on your behalf, for example to "deposit" to a contract address and/or to charge
    // fees in sub-currencies; the command should fail unless the _from account has
    // deliberately authorized the sender of the message via some mechanism; we propose
    // these standardized APIs for approval:
    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) returns (bool success) {
        if (balances[_from] >= _amount
            && allowed[_from][msg.sender] >= _amount
            && _amount > 0
            && balances[_to] + _amount > balances[_to]) {
            balances[_from] -= _amount;
            allowed[_from][msg.sender] -= _amount;
            balances[_to] += _amount;
            Transfer(_from, _to, _amount);
            return true;
        } else {
            return false;
        }
    }
 
    // Allow _spender to withdraw from your account, multiple times, up to the _value amount.
    // If this function is called again it overwrites the current allowance with _value.
    function approve(address _spender, uint256 _amount) returns (bool success) {
        allowed[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
        return true;
    }
 
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    function nextContractId() returns (uint256 contractId) {
        require(serviceContracts[msg.sender] > 0);
        return ++_nextAvailableContractId;
    }

    function openContract(uint256 _contractId, address _buyer, address _seller) {
        buyerContracts[_buyer].push(_contractId);
        sellerContracts[_seller].push(_contractId);
    }

    function enterIntoEscrow(uint256 _contractId, address _owner, uint256 _amount) returns (bool success) {
        if (serviceContracts[msg.sender] > 0
                && balances[_owner] >= _amount
                && _amount > 0) {
            balances[_owner] -= _amount;
            openContractsEscrow[_contractId] += _amount;
            return true;
        } else {
            return false;
        }
    }

    function removeFromEscrow(uint256 _contractId, address _recipient, uint256 _amount) returns (bool success) {
        if (serviceContracts[msg.sender] > 0
                && openContractsEscrow[_contractId] >= _amount
                && _amount > 0) {
            balances[_recipient] += _amount;
            openContractsEscrow[_contractId] -= _amount;        
            return true;
        } else {
            return false;
        }
    }

    function finalizeEscrow(uint256 _contractId, address _recipient, uint256 _amount, address _remainingRecipient) returns (bool success) {
        if (serviceContracts[msg.sender] > 0
                && openContractsEscrow[_contractId] >= _amount
                && _amount > 0) {
            balances[_recipient] += _amount;
            openContractsEscrow[_contractId] -= _amount;
            uint256 remainingAmount = openContractsEscrow[_contractId];
            if (remainingAmount > 0) {
                balances[_remainingRecipient] += remainingAmount;
                openContractsEscrow[_contractId] = 0;
            }
            return true;
        } else {
            return false;
        }
    }

    function balanceInEscrow(uint256 _contractId) returns (uint256 balance) {
        require(serviceContracts[msg.sender] > 0);
        return openContractsEscrow[_contractId];
    }

    serviceContractsSeller(address _address) {
        return sellerContracts[_address]; 
    }

    serviceContractsBuyer(address _address) {
        return sellerContracts[_address]; 
    }

}

contract ServiceContract {
  
}

contract TimedServiceContractManagement {

    address tokenContract;

    function TimedServiceContractManagement(address _tokenContract) {
        tokenContract = _tokenContract;
    }

    struct TimedServiceContract {
        uint256 id;
        address buyer;
        address seller;
        uint64 startTime;
        uint64 endTime;
        uint256 totalEscrowAmount;
        uint256 amountCollected;
        bool void;
    }

    mapping (uint256 => TimedServiceContract) serviceContracts;

    function openContract(address _buyer, address _seller, uint64 _startTime, uint64 _endTime, uint256 _escrowAmount) {
        // collect and verify signatures

        InfraToken token = new InfraToken(tokenContract);
        uint256 id = token.nextContractId();

        if (token.enterIntoEscrow(id, _buyer, _escrowAmount)) {
          TimedServiceContract memory serviceContract = TimedServiceContract({
            id: id,
            buyer: _buyer,
            seller: _seller,
            startTime: _startTime,
            endTime: _endTime,
            totalEscrowAmount: _escrowAmount,
            amountCollected: 0,
            void: false
          });
          serviceContracts[id] = serviceContract;
        } else {
          revert();
        }
    }

    function collect(uint256 _contractId) {

        TimedServiceContract storage serviceContract = serviceContracts[_contractId];
        require(msg.sender == serviceContract.seller
                && !serviceContract.void);

        uint256 value = serviceContract.totalEscrowAmount * (now - serviceContract.startTime)/(serviceContract.endTime - serviceContract.startTime);

        uint256 valueToCollect = value - serviceContract.amountCollected;
        require(valueToCollect > 0);
        serviceContract.amountCollected += value;

        // seller collects the difference
        InfraToken token = new InfraToken(tokenContract);
        if (!token.removeFromEscrow(serviceContract.id, serviceContract.seller, valueToCollect)) revert();

    }

    function voidContract(uint256 _contractId) {

        TimedServiceContract storage serviceContract = serviceContracts[_contractId];
        require(msg.sender == serviceContract.seller || msg.sender == serviceContract.buyer);

        uint256 sellerValue = serviceContract.totalEscrowAmount * (now - serviceContract.startTime)/(serviceContract.endTime - serviceContract.startTime);

        uint256 sellerValueToCollect = sellerValue - serviceContract.amountCollected;
        require(sellerValueToCollect > 0);
        serviceContract.amountCollected += sellerValue;

        // seller collects the difference
        InfraToken token = new InfraToken(tokenContract);
        if (!token.finalizeEscrow(serviceContract.id, serviceContract.seller, sellerValueToCollect, serviceContract.buyer)) revert();

        serviceContract.void = true;
    }

}

contract PayPerUseServiceContractManagement {

    address tokenContract;

    function PayPerUseServiceContractManagement(address _tokenContract) {
        tokenContract = _tokenContract;
    }

    struct PayPerUseServiceContract {
        uint256 id;
        address buyer;
        address seller;
        uint64 startTime;
        uint64 endTime;
        uint64 gracePeriod;
        uint256 totalEscrowAmount;
        uint256 amountCollected;
        bool void;
    }

    mapping (uint256 => PayPerUseServiceContract) serviceContracts;

    function openContract(address _buyer, address _seller, uint64 _startTime, uint64 _endTime, uint64 _gracePeriod, uint256 _escrowAmount) {
        // collect and verify signatures

        InfraToken token = new InfraToken(tokenContract);
        uint256 id = token.nextContractId();
        if (token.enterIntoEscrow(id, _buyer, _escrowAmount)) {
          PayPerUseServiceContract memory serviceContract = PayPerUseServiceContract({
            id: id,
            buyer: _buyer,
            seller: _seller,
            startTime: _startTime,
            endTime: _endTime,
            gracePeriod: _gracePeriod,
            totalEscrowAmount: _escrowAmount,
            amountCollected: 0,
            void: false
          });
          serviceContracts[id] = serviceContract;
        } else {
          revert();
        }
    }

    function collect(uint256 _contractId, bytes32 h, uint8 v, bytes32 r, bytes32 s, uint value) {

		    address signer;
		    bytes32 proof;

        PayPerUseServiceContract storage serviceContract = serviceContracts[_contractId];
        require(msg.sender == serviceContract.seller);

        // get signer from signature
        signer = ecrecover(h, v, r, s);

        // require valid signature
        require(signer == serviceContract.buyer);

        proof = sha3(this, value);

        // signature is valid but doesn't match the data provided
        require(proof == h);

        uint256 valueToCollect = value - serviceContract.amountCollected;
        require(valueToCollect > 0);
        serviceContract.amountCollected += value;

        // seller collects the difference
        InfraToken token = new InfraToken(tokenContract);
        if (!token.removeFromEscrow(serviceContract.id, serviceContract.seller, valueToCollect)) revert();

    }

}

contract KeyValueDatabaseServiceContract {

}
