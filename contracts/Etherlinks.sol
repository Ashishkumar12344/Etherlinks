
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title EtherLink
 * @dev Decentralized professional networking platform on Ethereum blockchain
 * @author EtherLink Development Team
 */
contract Project {
    
    // Struct for user profile information
    struct UserProfile {
        string name;
        string bio;
        string[] skills;
        uint256 connectionCount;
        bool isRegistered;
        uint256 registrationTime;
    }
    
    // Struct for connection between users
    struct NetworkConnection {
        address userA;
        address userB;
        uint256 connectionTime;
        bool isActive;
    }
    
    // State variables
    mapping(address => UserProfile) public userProfiles;
    mapping(bytes32 => NetworkConnection) public networkConnections;
    mapping(address => address[]) public userConnectionsList;
    
    address[] public allRegisteredUsers;
    uint256 public totalRegisteredUsers;
    uint256 public totalActiveConnections;
    
    // Events
    event UserRegistered(address indexed user, string name);
    event ConnectionCreated(address indexed user1, address indexed user2);
    event ProfileUpdated(address indexed user, string name);
    
    // Modifiers
    modifier onlyRegisteredUser() {
        require(userProfiles[msg.sender].isRegistered, "User must be registered first");
        _;
    }
    
    modifier userNotRegistered() {
        require(!userProfiles[msg.sender].isRegistered, "User already registered");
        _;
    }
    
    modifier validUserAddress(address _user) {
        require(_user != address(0), "Invalid user address");
        require(_user != msg.sender, "Cannot interact with yourself");
        require(userProfiles[_user].isRegistered, "Target user not registered");
        _;
    }
    
    /**
     * @dev Core Function 1: Register new user profile
     * @param _name User's display name
     * @param _bio User's professional biography
     * @param _skills Array of user's professional skills
     */
    function registerUser(
        string memory _name,
        string memory _bio,
        string[] memory _skills
    ) external userNotRegistered {
        require(bytes(_name).length > 0, "Name cannot be empty");
        require(bytes(_bio).length > 0, "Bio cannot be empty");
        require(_skills.length > 0, "Must specify at least one skill");
        
        userProfiles[msg.sender] = UserProfile({
            name: _name,
            bio: _bio,
            skills: _skills,
            connectionCount: 0,
            isRegistered: true,
            registrationTime: block.timestamp
        });
        
        allRegisteredUsers.push(msg.sender);
        totalRegisteredUsers++;
        
        emit UserRegistered(msg.sender, _name);
    }
    
    /**
     * @dev Core Function 2: Create connection between users
     * @param _targetUser Address of user to connect with
     */
    function createConnection(address _targetUser) 
        external 
        onlyRegisteredUser 
        validUserAddress(_targetUser) 
    {
        bytes32 connectionId = generateConnectionId(msg.sender, _targetUser);
        require(!networkConnections[connectionId].isActive, "Connection already exists");
        
        // Create bidirectional connection
        networkConnections[connectionId] = NetworkConnection({
            userA: msg.sender < _targetUser ? msg.sender : _targetUser,
            userB: msg.sender < _targetUser ? _targetUser : msg.sender,
            connectionTime: block.timestamp,
            isActive: true
        });
        
        // Update connection lists for both users
        userConnectionsList[msg.sender].push(_targetUser);
        userConnectionsList[_targetUser].push(msg.sender);
        
        // Increment connection counts
        userProfiles[msg.sender].connectionCount++;
        userProfiles[_targetUser].connectionCount++;
        
        totalActiveConnections++;
        
        emit ConnectionCreated(msg.sender, _targetUser);
    }
    
    /**
     * @dev Core Function 3: Get user's network connections
     * @param _user Address of user to query
     * @return userConnections Array of connected user addresses
     */
    function getUserConnections(address _user) 
        external 
        view 
        returns (address[] memory userConnections) 
    {
        require(userProfiles[_user].isRegistered, "User not registered");
        return userConnectionsList[_user];
    }
    
    /**
     * @dev Get detailed profile information for a user
     * @param _user Address of the user
     * @return name User's name
     * @return bio User's biography
     * @return skills User's skills array
     * @return connectionCount Number of connections
     * @return registrationTime When user registered
     */
    function getUserProfile(address _user) 
        external 
        view 
        returns (
            string memory name,
            string memory bio,
            string[] memory skills,
            uint256 connectionCount,
            uint256 registrationTime
        ) 
    {
        require(userProfiles[_user].isRegistered, "User profile does not exist");
        
        UserProfile memory profile = userProfiles[_user];
        return (
            profile.name,
            profile.bio,
            profile.skills,
            profile.connectionCount,
            profile.registrationTime
        );
    }
    
    /**
     * @dev Check if two users are connected
     * @param _userA First user address
     * @param _userB Second user address
     * @return connected True if users are connected
     */
    function checkConnection(address _userA, address _userB) 
        external 
        view 
        returns (bool connected) 
    {
        bytes32 connectionId = generateConnectionId(_userA, _userB);
        return networkConnections[connectionId].isActive;
    }
    
    /**
     * @dev Get platform statistics
     * @return registeredUsers Total number of registered users
     * @return activeConnections Total number of active connections
     */
    function getPlatformStatistics() 
        external 
        view 
        returns (uint256 registeredUsers, uint256 activeConnections) 
    {
        return (totalRegisteredUsers, totalActiveConnections);
    }
    
    /**
     * @dev Update user profile information
     * @param _name Updated name
     * @param _bio Updated biography
     * @param _skills Updated skills array
     */
    function updateUserProfile(
        string memory _name,
        string memory _bio,
        string[] memory _skills
    ) external onlyRegisteredUser {
        require(bytes(_name).length > 0, "Name cannot be empty");
        require(bytes(_bio).length > 0, "Bio cannot be empty");
        require(_skills.length > 0, "Must specify at least one skill");
        
        UserProfile storage profile = userProfiles[msg.sender];
        profile.name = _name;
        profile.bio = _bio;
        profile.skills = _skills;
        
        emit ProfileUpdated(msg.sender, _name);
    }
    
    /**
     * @dev Get all registered users on the platform
     * @return users Array of all registered user addresses
     */
    function getAllUsers() external view returns (address[] memory users) {
        return allRegisteredUsers;
    }
    
    /**
     * @dev Internal function to generate unique connection identifier
     * @param _userA First user address
     * @param _userB Second user address
     * @return connectionId Unique connection identifier
     */
    function generateConnectionId(address _userA, address _userB) 
        internal 
        pure 
        returns (bytes32 connectionId) 
    {
        return keccak256(abi.encodePacked(
            _userA < _userB ? _userA : _userB,
            _userA < _userB ? _userB : _userA
        ));
    }
}
