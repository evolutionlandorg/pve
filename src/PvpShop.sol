pragma solidity ^0.6.7;

import "ds-stop/stop.sol";
import "zeppelin-solidity/proxy/Initializable.sol";
import "zeppelin-solidity/token/ERC20/IERC20.sol";
import "zeppelin-solidity/token/ERC20/SafeERC20.sol";
import "./interfaces/ISettingsRegistry.sol";
import "./interfaces/IBoxBase.sol";

contract PvpShop is Initializable, DSStop {
    using SafeERC20 for IERC20;

    event BuyTicket(address indexed user, uint256 indexed season);
    event BuyCOO(address indexed user, uint256 indexed season);
	event ClaimedTokens(address indexed token, address indexed to, uint256 amount);

    bytes32 private constant CONTRACT_BOX_BASE = "CONTRACT_BOX_BASE";
    bytes32 private constant CONTRACT_DEV_POOL = "CONTRACT_DEV_POOL";
    bytes32 private constant CONTRACT_USDT_ERC20_TOKEN = "CONTRACT_USDT_ERC20_TOKEN";

    uint256 public ticketFee = 20e6;
    uint256 public cooFee = 10e6;
    uint256 public season;
    uint256 public seasonFinish;
    uint256 public seasonDuration = 90 days;

    ISettingsRegistry public registry;
    // user => season => bool
    mapping(address => mapping(uint256 => uint256)) tickets;

    modifier notContract() {
        require(!_isContract(msg.sender), "Contract not allowed");
        require(msg.sender == tx.origin, "Proxy contract not allowed");
        _;
    }

    function initialize(address _registry) public initializer {
        owner = msg.sender;
        emit LogSetOwner(msg.sender);
        registry = ISettingsRegistry(_registry);
    }

    function ticketOf(address _user, uint256 _season) public view returns (bool) {
        return tickets[_user][_season] == 1;
    }

    function buyTicket() notContract stoppable external {
        address user = msg.sender;
        require(seasonFinish > block.timestamp, "!start");
        require(ticketOf(user, season) == false, "!repeat");
        address usdt = registry.addressOf(CONTRACT_USDT_ERC20_TOKEN);
        IERC20(usdt).safeTransferFrom(user, address(this), ticketFee);
        _giveBox(user);
        tickets[user][season] = 1;
        emit BuyTicket(user, season);
    }

    function buyCOO() notContract stoppable external {
        address user = msg.sender;
        address pool = registry.addressOf(CONTRACT_DEV_POOL);
        address usdt = registry.addressOf(CONTRACT_USDT_ERC20_TOKEN);
        IERC20(usdt).safeTransferFrom(user, pool, cooFee);
        emit BuyCOO(user, season);
    }

    function _giveBox(address user) internal {
        address box = registry.addressOf(CONTRACT_BOX_BASE);
        IBoxBase(box).createBox(IBoxBase.Box.Gold, user, address(0), 0);
    }

    function setFee(uint256 _ticketFee, uint256 _cooFee) external auth {
        ticketFee = _ticketFee;
        cooFee = _cooFee;
    }

    function startNewSeason() external auth {
        require(seasonFinish < block.timestamp, "!end");
        season = season + 1;
        seasonFinish = block.timestamp + seasonDuration;
    }

	function claimTokens(address _token) external auth {
		if (_token == address(0)) {
			_makePayable(owner).transfer(address(this).balance);
			return;
		}
		IERC20 token = IERC20(_token);
		uint256 balance = token.balanceOf(address(this));
		token.transfer(owner, balance);
		emit ClaimedTokens(_token, owner, balance);
	}

	function _makePayable(address x) internal pure returns (address payable) {
		return address(uint160(x));
	}

    function _isContract(address _addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(_addr)
        }
        return size > 0;
    }
}
