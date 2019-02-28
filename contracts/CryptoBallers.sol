pragma solidity ^0.4.24;

import './ERC721.sol';

contract CryptoBallers is ERC721 {

    struct Baller {
        string name;
        uint level;
        uint offenseSkill;
        uint defenseSkill;
        uint winCount;
        uint lossCount;
    }

    address owner;
    Baller[] public ballers;

    // Mapping for if address has claimed their free baller
    mapping(address => bool) public claimedFreeBaller;
    
    // Mapping who owns each baller
    mapping(uint => address) public ballersOwners;
    
    //Number of ballers for each owner
    mapping(address => uint) public ownersToNumberOfBallers;

    // Fee for buying a baller
    uint ballerFee = 0.10 ether;

    /**
    * @dev Ensures ownership of the specified token ID
    * @param _tokenId uint256 ID of the token to check
    */
    modifier onlyOwnerOf(uint256 _tokenId) {
        require(msg.sender == ballersOwners[_tokenId]);
        _;
    }

    /**
    * @dev Ensures ownership of contract
    */
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner is allowed");
        _;
    }

    /**
    * @dev Ensures baller has level above specified level
    * @param _level uint level that the baller needs to be above
    * @param _ballerId uint ID of the Baller to check
    */
    modifier aboveLevel(uint _level, uint _ballerId) {
        require(ballers[_ballerId].level > _level);
        _;
    }

    constructor() public {
        owner = msg.sender;
    }

    function getNumBallers() public view returns (uint) {
        return ballers.length;
    }

    /**
    * @dev Allows user to claim first free baller, ensure no address can claim more than one
    */
    function claimFreeBaller() public {
        require(claimedFreeBaller[msg.sender] == false);
        claimedFreeBaller[msg.sender] = true;
        _createBaller("Free Baller", 1, 30, 30);
        ballersOwners[ballers.length - 1] = msg.sender;
        ownersToNumberOfBallers[msg.sender]++;
    }

    /**
    * @dev Allows user to buy baller with set attributes
    */
    function buyBaller() public payable {
        require(msg.value >= ballerFee, "Not enough ether to buy Baller");
        owner.transfer(ballerFee);
        _createBaller("Bought Baller", 1, 50, 50);
        ballersOwners[ballers.length - 1] = msg.sender;
        ownersToNumberOfBallers[msg.sender]++;
    }

    /**
    * @dev Play a game with your baller and an opponent baller
    * If your baller has more offensive skill than your opponent's defensive skill
    * you win, your level goes up, the opponent loses, and vice versa.
    * If you win and your baller reaches level 5, you are awarded a new baller with a mix of traits
    * from your baller and your opponent's baller.
    * @param _ballerId uint ID of the Baller initiating the game
    * @param _opponentId uint ID that the baller needs to be above
    */
    function playBall(uint _ballerId, uint _opponentId) onlyOwnerOf(_ballerId) public {
       if (ballers[_ballerId].offenseSkill*randomProbability() >= ballers[_opponentId].defenseSkill*(100 - randomProbability())) {
           ballers[_ballerId].level++;
           ballers[_ballerId].winCount++;
           ballers[_ballerId].offenseSkill++;
           ballers[_opponentId].lossCount++;
           if (ballers[_ballerId].level == 5) {
               (uint level, uint offense, uint defense) = _breedBallers(ballers[_ballerId], ballers[_opponentId]);
               _createBaller("New Baller", level, offense, defense);
               ballersOwners[ballers.length - 1] = msg.sender;
               ownersToNumberOfBallers[msg.sender]++;
           }
       } else {
           ballers[_ballerId].lossCount++;
           ballers[_opponentId].winCount++; 
           ballers[_opponentId].defenseSkill++;
       }
    }

    /**
    * @dev Changes the name of your baller if they are above level two
    * @param _ballerId uint ID of the Baller who's name you want to change
    * @param _newName string new name you want to give to your Baller
    */
    function changeName(uint _ballerId, string _newName) external aboveLevel(2, _ballerId) onlyOwnerOf(_ballerId) {
        ballers[_ballerId].name = _newName;
    }

    /**
   * @dev Creates a baller based on the params given, adds them to the Baller array and mints a token
   * @param _name string name of the Baller
   * @param _level uint level of the Baller
   * @param _offenseSkill offensive skill of the Baller
   * @param _defenseSkill defensive skill of the Baller
   */
    function _createBaller(string _name, uint _level, uint _offenseSkill, uint _defenseSkill) internal {
        ballers.push(Baller(_name, _level, _offenseSkill, _defenseSkill, 0 , 0));
    }

    /**
    * @dev Helper function for a new baller which averages the attributes of the level, attack, defense of the ballers
    * @param _baller1 Baller first baller to average
    * @param _baller2 Baller second baller to average
    * @return tuple of level, attack and defense
    */
    function _breedBallers(Baller _baller1, Baller _baller2) internal pure returns (uint, uint, uint) {
        uint level = (_baller1.level+(_baller2.level))/2;
        uint attack = (_baller1.offenseSkill+(_baller2.offenseSkill))/2;
        uint defense = (_baller1.defenseSkill+(_baller2.defenseSkill))/2;
        return (level, attack, defense);

    }
    
    function getBallersByOwner(address _owner) external view returns(uint[]) {
        uint[] memory result = new uint[](ownersToNumberOfBallers[_owner]);
        uint counter = 0;
        for (uint i = 0; i < ballers.length; i++) {
            if (ballersOwners[i] == _owner) {
                result[counter] = i;
                counter++;
            }
        }
        return result;
    }
  
  function randomProbability () private view returns(uint) {
      return (uint(keccak256(abi.encodePacked(now, msg.sender))) % 100);
  }
}