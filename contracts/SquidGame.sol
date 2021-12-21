// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";

contract SquidGame is Context, Ownable {
        bool private finished;
        uint256 private registrationFee;
        uint256 private requiredAmount;

        struct winners {
            uint256 rank;
            uint256 prize;
        }

        // Function to receive Ether.
        receive() external payable {

        }

        mapping(address => bool) private participants;
        
        mapping(address => bool) private stage1;
        mapping(address => bool) private stage2;
        mapping(address => bool) private stage3;
        mapping(address => winners) private stage4;
         
        IERC20 private immutable _laqiraToken;
        IERC20 private immutable _squidToken;

        constructor(IERC20 laqiraToken_, IERC20 squidToken_) {
            _laqiraToken = laqiraToken_;
            _squidToken = squidToken_;
        }

        //Using this function, participants can register into the event by paying registration fee
        function register() public payable notFinished {
            uint256 transferredAmount = msg.value;
            require(laqiraToken().balanceOf(_msgSender()) >= requiredAmount &&
            squidToken().balanceOf(_msgSender()) >= requiredAmount);
            require(!isParticipant(_msgSender()));
            require(transferredAmount >= registrationFee);
            participants[_msgSender()] = true;
        }

        //Using the function, event admin can set an entrance fee for participants
        function setFee(uint256 _fee) public onlyOwner {
            registrationFee = _fee;
        }

        function setFinished() public onlyOwner {
           finished = !finished;
        }

        function setTokenAmount(uint256 _amount) public onlyOwner {
            requiredAmount = _amount;
        } 

        function setStage1Pass(address _participant) public onlyOwner {
            stage1[_participant] = true;
        }

        function setStage2Pass(address _participant) public onlyOwner {
            stage2[_participant] = true;
        }

        function setStage3Pass(address _participant) public onlyOwner {
            stage3[_participant] = true;
        }

        function setStage4Pass(address _participant, uint256 _rank, uint256 _prize) public onlyOwner {
            stage4[_participant].rank = _rank;
            stage4[_participant].prize = _prize;
        }

        function claimReward() public {
            require(stage4[_msgSender()].prize > 0);
            address payable client = payable(_msgSender());
            client.transfer(stage4[_msgSender()].prize);
            stage4[_msgSender()].prize = 0;
        }

        function adminWithdrawal(uint256 _amount) public onlyOwner {
            address payable _owner = payable(owner());
            _owner.transfer(_amount);
        }

        function finishedStatus() public view returns (bool _status) {
            return finished;
        }

        function isParticipant(address _participant) public view returns (bool) {
            return participants[_participant];
        }

        function laqiraToken() public view virtual returns (IERC20) {
            return _laqiraToken;
        }

        function squidToken() public view virtual returns (IERC20) {
            return _squidToken;
        }

       modifier notFinished() {
           require(!finished, 'Registration period has ended');
           _;
       }
}
