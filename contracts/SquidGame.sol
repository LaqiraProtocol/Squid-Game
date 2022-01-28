// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract SquidGame is Context, Ownable {
        using Counters for Counters.Counter;

        Counters.Counter private _counter;

        bool private finished;
        uint256 private registrationFee;
        uint256 private requiredAmount;
        address private feeAddress;

        event Claim(address _participant, uint256 _prize, uint8 rank);

        struct winners {
            uint8 rank;
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

        constructor(IERC20 laqiraToken_, IERC20 squidToken_, address feeAddress_) {
            _laqiraToken = laqiraToken_;
            _squidToken = squidToken_;
            feeAddress = feeAddress_;
        }

        //Using this function, participants can register into the event by paying registration fee
        function register() public payable notFinished {
            uint256 transferredAmount = msg.value;
            require(laqiraToken().balanceOf(_msgSender()) >= requiredAmount, 'Insufficient LQR balance');
            require(squidToken().balanceOf(_msgSender()) >= requiredAmount, 'Insufficient SQUID balance');
            require(!isParticipant(_msgSender()), 'Participant already exists');
            require(transferredAmount >= registrationFee, 'Insufficient fund for registration');
            (bool success, ) = feeAddress.call{value: transferredAmount}(new bytes(0));
            require(success, 'Transfer failed');
            participants[_msgSender()] = true;
            _counter.increment();
        }

        //Using the function, event admin can set an entrance fee for participants
        function setFee(uint256 _fee) public onlyOwner {
            registrationFee = _fee;
        }

        //This function is used for closing event registration period
        function setFinished() public onlyOwner {
           finished = !finished;
        }

        //Using this function, admin can set the minimum number of special token that participants should
        //have in their wallets for registration
        function setTokenAmount(uint256 _amount) public onlyOwner {
            requiredAmount = _amount;
        }

        function setFeeAddress(address _newAddress) public onlyOwner {
            feeAddress = _newAddress;
        }

        function batchSetStage(address[] memory _participants, uint8 _stageNumber) public onlyOwner {
            uint256 i;
            uint256 arrayLen = _participants.length;
            if (_stageNumber == 1) {
                for (i = 0; i < arrayLen; i++) { 
                    if (isParticipant(_participants[i]))
                        setStage1Pass(_participants[i]);
                    else
                        continue;
                }
            } else if (_stageNumber == 2) {
                for (i = 0; i < arrayLen; i++) {
                    if (isAtStage1(_participants[i]))
                        setStage2Pass(_participants[i]);
                    else 
                        continue;
                }
            } else if (_stageNumber == 3) {
                for (i = 0; i < arrayLen; i++) 
                    if (isAtStage2(_participants[i]))
                        setStage3Pass(_participants[i]);
                    else 
                        continue;
            }
        }

        function batchSetStage4(address[] memory _participants, uint8[] memory _rank, uint256[] memory _prize) public onlyOwner {
            require(_participants.length == _rank.length && _rank.length == _prize.length, 'Wrong len');
            for (uint256 i = 0; i < _participants.length; i++) {
                if (isAtStage3(_participants[i])) {
                    setStage4Pass(_participants[i], _rank[i], _prize[i]);
                } else {
                    continue;
                }
            }
        }

        function lotteryWinner(address _winner, uint256 _prize) public onlyOwner {
            stage4[_winner].prize = _prize;
            stage4[_winner].rank = 0;
        }

        //Using the function, winners can claim their prize
        function claimReward() public {
            uint256 prize = stage4[_msgSender()].prize;
            require(prize > 0, 'Prize must be greater than 0');
            address payable client = payable(_msgSender());
            client.transfer(prize);
            stage4[_msgSender()].prize = 0;
            emit Claim(_msgSender(), prize, stage4[_msgSender()].rank);
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

        function getRegisteredParticipants() public view returns (uint256) {
            return _counter.current();            
        }

        function fee() public view returns (uint256) {
            return registrationFee;
        }

        function getRequiredAmount() public view returns (uint256) {
            return requiredAmount;
        }

        modifier notFinished() {
            require(!finished, 'Registration period has ended');
           _;
        }

        function isAtStage1(address _participant) public view returns (bool) {
            return stage1[_participant];
        }

        function isAtStage2(address _participant) public view returns (bool) {
            return stage2[_participant];
        }

        function isAtStage3(address _participant) public view returns (bool) {
            return stage3[_participant];
        }

         //Function is called by the owner, when a participant passes stage 1, successfully
        function setStage1Pass(address _participant) internal {
            stage1[_participant] = true;
        }

        //Function is called by the owner, when a participant passes stage 2, successfully
        function setStage2Pass(address _participant) internal {
            stage2[_participant] = true;
        }

        //Function is called by the owner, when a participant passes stage 3, successfully
        function setStage3Pass(address _participant) internal {
            stage3[_participant] = true;
        }

        //Function is called by the owner for a winner participant to set his/her rank and prize
        function setStage4Pass(address _participant, uint8 _rank, uint256 _prize) internal {
            stage4[_participant].rank = _rank;
            stage4[_participant].prize = _prize;
        }

        function isAtStage4(address _participant) public view returns (uint8 _rank, uint256 _prize) {
            winners memory winner = stage4[_participant];
            return (winner.rank, winner.prize);
        }
}
