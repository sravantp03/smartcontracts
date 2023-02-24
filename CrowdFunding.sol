// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IERC20 {
    function transfer(address, uint) external returns (bool);

    function transferFrom(address, address, uint) external returns (bool);
}

contract CrowdFunding {
    event Lauch(
        uint256 indexed id,
        address indexed creator,
        uint256 goalAmount,
        uint256 startAt,
        uint256 endAt
    );
    event Cancel(uint256 indexed id);
    event Pledge(uint256 indexed id, address indexed caller, uint256 amount);
    event Unpledge(uint256 indexed id, address indexed caller, uint256 amount);
    event Claim(uint256 indexed id);
    event Refund(uint256 id, address indexed caller, uint256 balance);

    struct Campaign {
        address creator;
        uint256 goalAmount;
        uint256 pledged;
        uint256 startAt;
        uint256 endAt;
        bool claimed;
    }

    IERC20 public immutable token;
    uint256 public count;
    mapping(uint256 => Campaign) public campaigns;
    mapping(uint256 => mapping(address => uint256)) public pledgedAmount;

    constructor(address _token) {
        token = IERC20(_token);
    }

    function launch(uint256 _goal, uint256 _startAt, uint256 _endAt) external {
        require(_startAt >= block.timestamp, "Wrong starting time");
        require(_endAt > _startAt, "end time < start time");
        require(_endAt <= _startAt + 90 days, "Wrong end time");

        count++;
        campaigns[count] = Campaign(
            msg.sender,
            _goal,
            0,
            _startAt,
            _endAt,
            false
        );
        emit Lauch(count, msg.sender, _goal, _startAt, _endAt);
    }

    function cancel(uint256 _id) external {
        require(_id <= count, "Invalid Campaign");
        Campaign memory campaign = campaigns[_id];
        require(msg.sender == campaign.creator, "You are not the creator");
        require(block.timestamp < campaign.startAt, "You can't cancel"); // can't cancel campaign once it has started.

        delete campaigns[_id]; // deleting campaign.
        emit Cancel(_id);
    }

    function pledge(uint256 _id, uint256 _amount) external {
        require(_id <= count, "Invaid Campaing");
        require(_amount > 0, "Invalid amount");
        Campaign storage campaign = campaigns[_id];
        require(
            block.timestamp >= campaign.startAt,
            "Campaign not started yet"
        );
        require(block.timestamp <= campaign.endAt, "Campaign has ended");

        campaign.pledged += _amount;
        pledgedAmount[_id][msg.sender] += _amount;
        token.transferFrom(msg.sender, address(this), _amount);

        emit Pledge(_id, msg.sender, _amount);
    }

    function unpledge(uint256 _id, uint256 _amount) external {
        require(
            pledgedAmount[_id][msg.sender] > 0,
            "You didn't pledge anything"
        );
        Campaign storage campaign = campaigns[_id];
        require(block.timestamp < campaign.endAt, "Campaign has already ended");
        require(_amount <= pledgedAmount[_id][msg.sender], "Invalid amount");

        campaign.pledged -= _amount;
        pledgedAmount[_id][msg.sender] -= _amount;
        token.transfer(msg.sender, _amount);

        emit Unpledge(_id, msg.sender, _amount);
    }

    function claim(uint256 _id) external {
        Campaign storage campaign = campaigns[_id];
        require(msg.sender == campaign.creator, "You are not the creator");
        require(block.timestamp > campaign.endAt, "Not ended");
        require(campaign.pledged >= campaign.goalAmount, "Not received enough");
        require(!campaign.claimed, "claimed");

        campaign.claimed = true;
        token.transfer(msg.sender, campaign.pledged);

        emit Claim(_id);
    }

    function refund(uint256 _id) external {
        Campaign storage campaign = campaigns[_id];
        require(block.timestamp > campaign.endAt, "Not ended");
        require(
            campaign.pledged < campaign.goalAmount,
            "Campaign secured enough funds"
        );

        uint256 balance = pledgedAmount[_id][msg.sender];
        pledgedAmount[_id][msg.sender] = 0;
        token.transfer(msg.sender, balance);

        emit Refund(_id, msg.sender, balance);
    }
}
