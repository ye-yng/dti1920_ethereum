pragma solidity ^0.6.0;
contract AcademicService {

 //a student not yet available has grade = -1
    struct Course {
        uint8 credits;
        address professor;
        mapping(address => int) grades;
    }

    struct Student {
        address student;
        uint8 registeredCredits;
        uint8 approvedCredits;
    }

    address payable public school;
    uint256 public start;
    Course[] public courses;
    mapping(address => Student) students;

    event AcquiredDegree(address who);

    //modifier that checks if the sender is the school
    modifier onlySchool(){
        require(msg.sender == school, "Sender is not school.");
        _;
    }

    // This is the constructor whose code is
    // run only when the contract is created.
    constructor(address[] memory studentAddresses, uint8[] memory courseCredits) public {
        school = msg.sender;
        start = now;

        for(uint i = 0; i<courseCredits.length; i++) {
            courses.push(Course(courseCredits[i],address(0)));
        }

        for(uint i = 0; i<studentAddresses.length; i++) {
            students[studentAddresses[i]] = Student(studentAddresses[i],0,0);
        }
    }

    function assignProfessor(uint8 courseId, address professor) external onlySchool{
        if( courseId > 0 &&
            courseId < courses.length &&
            courses[courseId].professor != address(0) &&
            now < (start + 1 days)) {
            //TODO array access makes no sense here, should be index instead of courseId
            courses[courseId].professor = professor;
        }
    }

    function registerNewStudent(address studentAddress) external onlySchool {
        //address(0) is an empty address, since mappings always return structs,
        //we check if the address of the Studen struct is empty

        if(now < (start + 4 weeks) &&
            students[studentAddress].student == address(0)) {

            students[studentAddress] = Student(studentAddress,0,0);
        }
    }

    function registerOnCourse(uint8 courseId) public payable {
        uint256 cost;
        if(courseId > 0 && courseId < courses.length) {
            if(students[msg.sender].registeredCredits >= 60) {
                cost = courses[courseId].credits*(0.1 ether);
            } else {
                cost = (courses[courseId].credits -
                (60-students[msg.sender].registeredCredits))*
                (0.1 ether);
            }

            if(cost <= 0 || msg.value >= cost) {
                courses[courseId].grades[msg.sender] = -1;
                students[msg.sender].registeredCredits += courses[courseId].credits;
                school.transfer(cost);
            }
        }
    }
}