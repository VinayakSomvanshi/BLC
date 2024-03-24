pragma solidity 0.5.16;

contract Lottery {
    // Struct used to store user information
    struct User {
        address userAddress;
        uint tokensBought;
        uint[] guess;
    }

    // A list of users
    mapping (address => User) public users;
    address[] public userAddresses;
    address payable public owner;  // Change here to address payable
    bytes32 winningGuessSha3;

    // Constructor function
    constructor(uint _winningGuess) public {
        // By default, the owner of the contract is accounts[0]
        // To set the owner, change truffle.js
        owner = msg.sender;
        winningGuessSha3 = keccak256(abi.encodePacked(_winningGuess));
    }

    // Returns the number of tokens purchased by an account
    function userTokens(address _user) view public returns (uint) {
        return users[_user].tokensBought;
    }

    // Returns the guess made by the user so far
    function userGuesses(address _user) view public returns (uint[] memory) {
        return users[_user].guess;
    }

    // Returns the winning guess
    function winningGuess() view public returns (bytes32) {
        return winningGuessSha3;
    }

    // Adds a new user to the contract to make guesses
    function makeUser() public {
        users[msg.sender].userAddress = msg.sender;
        users[msg.sender].tokensBought = 0;
        userAddresses.push(msg.sender);
    }

    // Adds tokens to the user that calls the contract
    // The money held in the contract is sent using a payable modifier function
    // Money can be released using selfdestruct(address)
    function addTokens() payable public {
        uint present = 0;
        uint tokensToAdd = msg.value / (10**18);

        for(uint i = 0; i < userAddresses.length; i++) {
            if(userAddresses[i] == msg.sender) {
                present = 1;
                break;
            }
        }

        // Adding tokens if the user is present in the userAddresses array
        if (present == 1) {
            users[msg.sender].tokensBought += tokensToAdd;
        }
    }

    // Adds user guesses
    function makeGuess(uint _userGuess) public {
        require(_userGuess < 1000000 && users[msg.sender].tokensBought > 0);
        users[msg.sender].guess.push(_userGuess);
        users[msg.sender].tokensBought--;
    }

    // Doesn't allow anyone to buy any more tokens
    function closeGame() public view returns (address) {
        // Can only be called by the owner of the contract
        require(owner == msg.sender);
        address winner = winnerAddress();
        return winner;
    }

    // Returns the address of the winner once the game is closed
    function winnerAddress() public view returns (address) {
        for(uint i = 0; i < userAddresses.length; i++) {
            User memory user = users[userAddresses[i]];

            for(uint j = 0; j < user.guess.length; j++) {
                if (keccak256(abi.encodePacked(user.guess[j])) == winningGuessSha3) {
                    return user.userAddress;
                }
            }
        }
        // The owner wins if there are no winning guesses
        return owner;
    }

    // Sends 50% of the ETH in the contract to the winner and the rest to the owner
    function getPrice() public returns (uint) {
        require(owner == msg.sender);
        address payable winner = address(uint160(winnerAddress()));  // Change here to address payable

        if (winner == owner) {
            owner.transfer(address(this).balance);
        } else {
            // Returns half the balance of the contract
            uint toTransfer = address(this).balance / 2;

            // Transfers 50% to the winner
            winner.transfer(toTransfer);
            // Transfers the rest of the balance to the owner of the contract
            owner.transfer(address(this).balance);
        }
        return address(this).balance;
    }
}

