// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Owner
 * @dev Set & change owner
 */
contract HelloWorld {
    
    enum Status{
        UKNOWN,
        CONNECTED, 
        BLOCKED,
        JOINED, 
        AWAITING, 
        REQUESTED
    }
    
    mapping(bytes => uint256) private _messagePos;
    mapping(bytes => mapping(uint256 => string)) private _messages;
    mapping(bytes => Status) private _connection;
    mapping(address => mapping(address => Status)) private _contacts;
    mapping(address => uint256) private _contactsPos;
    mapping(uint256 => address) private _contactsPointer;
    mapping(address => Status) private _users;
    
    function getConnection(address from, address to) public view returns(Status){
        bytes memory chatId = getChatId(from, to);
        Status connection = _connection[chatId];
        require(connection == Status.CONNECTED , "These address were not connected!");
        return connection;
    }
    
    function sendMessage(address to, string memory message) public onlyJoined() {
        Status connection = getConnection(msg.sender, to);
        require(connection == Status.CONNECTED, "These addresses were not connected!");
        bytes memory chatId = getChatId(msg.sender, to);
        uint256 position = getLastMessagePosition(chatId);
        _messages[chatId][position + 1] = message;
    }
    
    function acceptConnection(address target) public onlyJoined() {
        Status targetStatus = _users[target];
        require(targetStatus == Status.JOINED, "Target not joined!");
        
        Status contactStatus = _contacts[target][msg.sender];
        require(contactStatus == Status.REQUESTED, 'Connection is not requested by target!');
        
        _contacts[target][msg.sender] = Status.CONNECTED;
        _contacts[msg.sender][target] = Status.CONNECTED;
    }
    
    modifier onlyJoined {
        require(_users[msg.sender] == Status.JOINED, "Sender is not joined!");
        _;
    }
    
    
    function requestConnection(address target) public onlyJoined() {
        Status targetStatus = _users[target];
        require(targetStatus == Status.JOINED, "Target not joined!");
        
        Status contactStatus = _contacts[msg.sender][target];
        
        if (contactStatus == Status.AWAITING){
            _contacts[target][msg.sender] = Status.CONNECTED;
            _contacts[msg.sender][target] = Status.CONNECTED;
        } else {
            _contacts[target][msg.sender] = Status.AWAITING;
            _contacts[msg.sender][target] = Status.REQUESTED;
        }
         _contactsPos[msg.sender] += 1;
         _contactsPointer[_contactsPos[msg.sender]] = target;
        
    }
    
    function getChatId(address a, address b) public pure returns(bytes memory) {
        bytes memory chatId;
        if (a > b){
            chatId = abi.encodePacked(a, b);
        } else {
            chatId = abi.encodePacked(b, a);
        }
        return chatId;
    }
    
    function join() public {
        Status myStatus = _users[msg.sender];
        require(myStatus == Status.JOINED, "Already Joined!");
        _users[msg.sender] = Status.JOINED;
    }
    
    function getStatus() public view returns (Status){
        Status myStatus = _users[msg.sender];
        return myStatus;
    }
    
    function getMessage(bytes memory chatId, uint256 position) public view returns(string memory message){
        Status connection = _connection[chatId];
        require(connection == Status.CONNECTED, "These addresses were not connected!");
        uint256 lastPosition = getLastMessagePosition(chatId);
        require(position > 0 && position < lastPosition, "Invalid position!");
        return _messages[chatId][position];
    }
    
    function getLastMessagePosition(bytes memory chatId) public view returns(uint256){
        Status connection = _connection[chatId];
        require(connection == Status.CONNECTED, "These addresses were not connected!");
        return _messagePos[chatId];
    }
}