// contracts/Gurukul.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract Gurukul {

    address owner;
    using Counters for Counters.Counter;
    Counters.Counter private courseIds;
    //Creating constant parameters for now - ONLY FOR HACKATHON
    //Will change based on the length of course and other parameters
    uint256 public constant CREATOR_STAKE = 100;

    //Will change based on the type of course and other parameters
    uint256 public constant STUDENT_STAKE = 50;
    ERC20 guruToken;

    struct Course {
        address creator;
        uint256 courseId;
        string name;
    }

    mapping(address => uint256[]) creatorCourseMap;
    mapping(uint256 => Course) courseMap;
    mapping(address => uint256[]) studentCourseMap;
    mapping(address => mapping(uint256 => bool)) courseCompletion;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    constructor(address guruTokenAddress) {
        guruToken = ERC20(guruTokenAddress);
        owner = msg.sender;
    }

    function depositToken(address tokenOwner, uint256 amount) internal {
            uint256 amountToDeposit = amount * (1 ether);
            uint256 balance = guruToken.balanceOf(tokenOwner);
            require(balance >= amountToDeposit,"Balance is low");

            guruToken.transferFrom(tokenOwner, address(this),amountToDeposit);


    } 

    function createCourse(string memory name) public {

        courseIds.increment();
        uint256 courseId = courseIds.current();
        //Step1: Deposit the creator stake
        depositToken(msg.sender, CREATOR_STAKE);
        Course memory course = Course(msg.sender, courseId , name);
        creatorCourseMap[msg.sender].push(courseId);
        courseMap[courseId] = course;
    }

    function joinCourse(uint256 courseId) public {
        //Step1: Deposit the student stake
        depositToken(msg.sender, STUDENT_STAKE);
        
        studentCourseMap[msg.sender].push(courseId);
        courseCompletion[msg.sender][courseId] = false;
    }

    function completeCourse(uint256 courseId) public {
        require(courseCompletion[msg.sender][courseId] == false, "Student has already completed this course");
        bool hasEnrolled = false;

        //Checking if the student enrolled in this course
        for(uint i = 0; i < studentCourseMap[msg.sender].length; i++) {
            if(studentCourseMap[msg.sender][i] == courseId) {
                hasEnrolled = true;
            }
        }

        require(hasEnrolled, "Student has not enrolled in this course");
        courseCompletion[msg.sender][courseId] = true;
        address courseCreator = courseMap[courseId].creator;

        //Distributing staked money - 80% to student, 10% to creator and 10% to platform
        //Platform amount remains in the contract
        uint256 studentAmount = 30 * 1 ether;
        uint256 creatorAmount = 10 * 1 ether;


        uint256 guruBalance = guruToken.balanceOf(owner);
        require(guruBalance > (STUDENT_STAKE * 1 ether), "Not enough balance in the pool");

        guruToken.transferFrom(owner, msg.sender, studentAmount);
        guruToken.transferFrom(owner, payable(courseCreator), creatorAmount);

    }

    function withDrawFunds(uint256 amount) public onlyOwner {
        uint256 amountToDeposit = amount * (1 ether);
        uint256 balance = guruToken.balanceOf(address(this));
        require(balance >= amountToDeposit,"Balance is low");

        guruToken.transferFrom(address(this), msg.sender, amountToDeposit);
    }

}

/**
 * @title Guru
 * @dev Very simple ERC20 Token example, where all tokens are pre-assigned to the creator.
 * Note they can later distribute these tokens as they wish using `transfer` and other
 * `ERC20` functions.
 * Based on https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v2.5.1/contracts/examples/SimpleToken.sol
 */
contract Guru is ERC20 {
    /**
     * @dev Constructor that gives msg.sender all of existing tokens.
     */
    constructor(
    ) ERC20("Gurukul", "GURU") {
        //Minting 10 million GURU tokens
        uint256 totalSupply = 10000000 * 1 ether;
        _mint(msg.sender, totalSupply);
    }

}
