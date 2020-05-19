// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.8;

contract AcademicService {
    
    struct Course {
        uint8 credits;
        address payable professor;
        mapping(address => int) grades;
    }

    struct Student {
        address payable student;
        uint8 registeredCredits;
        uint8 approvedCredits;
    }

    address payable public school;
    uint256 public start;
    Course[] public courses;
    mapping(address => Student) students;

    event AcquiredDegree(address student);
    event GradeAssigned(address student);
    
    // This is the constructor whose code is
    // run only when the contract is created.
    constructor(address payable[] memory studentAddresses) public {
        school = msg.sender;
        start = now;

        uint8 totalCredits = 0;
        uint8[5] memory courseCredits= [3,6,6,3,6];
        for(uint i = 0; i < courseCredits.length; i++) {
            require(courseCredits[i] == 6 || courseCredits[i] == 3, "Course credits must be 6 or 3");
            totalCredits = totalCredits + courseCredits[i];
        }

        require(totalCredits > 18, "Total amount of credits must be larger than 18.");
        for(uint i = 0; i<courseCredits.length; i++) {
            courses.push(Course(courseCredits[i],address(0)));
        }

        for(uint i = 0; i < studentAddresses.length; i++) {
            students[studentAddresses[i]] = Student(studentAddresses[i],0,0);
        }
    }
    
    // ------------------- Modifiers ----------------------

    //This modifier is used on all functions that can only be accessed by the school
    modifier onlySchool(){
        require(msg.sender == school, "Sender must be the school.");
        _;
    }

    //This modifier is used on all functions that can only be accessed by a student
    modifier onlyStudent(){
        require(students[msg.sender].student == msg.sender, "Sender must be a student.");
        _;
    }

    //This modifier is used on all functions that can only be accessed by a professor
    modifier onlyProfessor(){
        bool isProfessor = false;
        for(uint i = 0; i < courses.length; i++){
            if(courses[i].professor == msg.sender){
                isProfessor = true;
                break;
            }
        }
        require(isProfessor, "Sender is not a professor.");
        _;
    }
    
    // ------------------ User Cases---------------------

    //Covers point 3 - School can associate one professor to each course
    function assignProfessor(uint8 courseId, address payable professor) external onlySchool{
        //Ensures that the assignment process is being done in the first 2 days of contract creation
        require(now < start + 2 days, "Can only assign professor on the first 2 days of the contract creation.");
        //Checks if courseID is valid
        require(courseId >= 0 && courseId < courses.length, "Invalid course ID.");
        //Checks if course does not have a professor associated
        require(courses[courseId].professor == address(0), "Course already has a professor associated.");
        //Associates the professor to the course
        courses[courseId].professor = professor;
    }

    //Covers point 4 - School can add new students to the initial list
    function registerStudents(address payable[] calldata studentAddresses) external onlySchool {
        //Ensures that the student is being registered within the first week
        require(now < start + 1 weeks, "Students can only be registered within the first week of the contract creation." );
        //Checks that student doesn't already exist
        for(uint i = 0; i < studentAddresses.length; i++){
            //if the student does not exists, we register its address
            if(students[studentAddresses[i]].student == address(0)){
                students[studentAddresses[i]] = Student(studentAddresses[i],0,0);
            }
        }
    }

    //Covers point 5 and 7 - Student can register
    function registerOnCourse(uint8 courseId) external payable onlyStudent{
        //Ensures that the student is registering on the first 2 weeks
        require(now < 2 weeks, "Student's can only register themselves within the first 2 weeks.");
        //Ensures that the registering student is new in the course
        require(students[msg.sender].student != address(0), "Student must be new in the course.");
        //Ensures that the course id is valid
        require(courseId >= 0 && courseId < courses.length, "Invalid course ID.");
        //Covers rule 5
        require(now < 2 weeks, "Student's can only register themselves within the first 2 weeks.");
        
        uint256 cost = 0;
        //Charges the student if the student has at least 18 registered credits
        if(students[msg.sender].registeredCredits >= 18) {
            cost = courses[courseId].credits*(0.001 ether);
        }

        //Default values of Int is 0, so when a student is registered to the course, we change the value to -1
        courses[courseId].grades[msg.sender] = -1;
        students[msg.sender].registeredCredits += courses[courseId].credits;
        school.transfer(cost);
    }

    //Cover point 6 - Student can unregister
    function unregisterCourse(uint8 courseId) external onlyStudent{
        //Ensures that the student is unregistering on the first month of the contract
        require(now < start + 31 days, "Can only unregister during the first month of the contract.");
        //Ensures that the unregistering student is registered in the academic year
        require(students[msg.sender].student == msg.sender, "Student must be registered in the academic year.");
        //Ensures that the unregistering student is registered in course
        require(courses[courseId].grades[msg.sender] == -1, "Student must be registered in the course.");
        //Ensures that the course id is valid
        require(courseId >= 0 && courseId < courses.length, "Invalid course ID.");
        
        //TODO onde viste esta regra?
        //require(students[msg.sender].registeredCredits - courseCredits >= 0, "Insufficient registered credits on student.");
        
        //Unregisters student
        courses[courseId].grades[msg.sender] = 0;
        uint8 currCredits = students[msg.sender].registeredCredits;
        //Updates student's registered credits based on the course from which the student unregistered
        students[msg.sender].registeredCredits = currCredits - courses[courseId].credits;
    }
}