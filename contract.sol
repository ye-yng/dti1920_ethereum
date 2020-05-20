// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.8;

contract AcademicService {
    
    struct Course {
        uint8 credits;
        address payable professor;
        mapping(address => int) grades;
        mapping(address => bool) registered;
        mapping (address => bool) gradeChange;
        //used  to check when there has been a grade approval
        uint8 gradeApprovals;
    }

    struct Student {
        address student;
        uint8 registeredCredits;
        uint8 approvedCredits;
    }

    address payable private school;
    uint256 private start;
    Course[] private courses;
    address[] private listStudentsAddr;
    mapping(address => Student) students;

    event AcquiredDegree(address from, address who, address to); 
    event GradeAssigned(address from, address to, uint8 courseId, int grade); 
    
    //Covers point 1 and 2
    constructor(address[] memory studentAddresses) public {
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
            listStudentsAddr.push(studentAddresses[i]);
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
                listStudentsAddr.push(studentAddresses[i]);
            }
        }
    }

    //Covers point 5 - Student can register itself in the contract courses on the first 2 weeks
    //Covers point 7 - free registation up to 18 credits
    function registerOnCourse(uint8 courseId) external payable onlyStudent {
        //Ensures that the course id is valid
        require(courseId >= 0 && courseId < courses.length, "Invalid course ID.");
        //Ensures that the student is registering on the first 2 weeks
        require(now < start + 2 weeks, "Student's can only register themselves within the first 2 weeks.");
        //Ensures that the registering student is registered in the academic year
        require(students[msg.sender].student == msg.sender, "Student must be registered in the academic year.");
        //Ensures that the registering student is new in the course
        require(courses[courseId].registered[msg.sender] == false, "Student must be new in the course.");
        
        uint256 cost = 0;
        //Charges the student if the student has at least 18 registered credits
        if(students[msg.sender].registeredCredits >= 18) {
            cost = courses[courseId].credits*(0.001 ether);
        }

        //Default values of Int is 0, so when a student is registered to the course, we change the value to -1
        courses[courseId].grades[msg.sender] = -1;
        courses[courseId].registered[msg.sender] = true;
        students[msg.sender].registeredCredits += courses[courseId].credits;
        school.transfer(cost);
    }

    //Covers point 6 - Student can unregister
    function unregisterCourse(uint8 courseId) external onlyStudent{
        //Ensures that the course id is valid
        require(courseId >= 0 && courseId < courses.length, "Invalid course ID.");
        //Ensures that the student is unregistering on the first month of the contract
        require(now < start + 31 days, "Can only unregister during the first month of the contract.");
        //Ensures that the unregistering student is registered in the academic year
        require(students[msg.sender].student == msg.sender, "Student must be registered in the academic year.");
        //Ensures that the unregistering student is registered in course
        require(courses[courseId].registered[msg.sender] == true, "Student must be registered in the course.");
        
        //TODO onde viste esta regra?
        //require(students[msg.sender].registeredCredits - courseCredits >= 0, "Insufficient registered credits on student.");
        
        //Unregisters student
        courses[courseId].grades[msg.sender] = 0;
        courses[courseId].registered[msg.sender] = false;
        //Updates student's registered credits based on the course from which the student unregistered
        students[msg.sender].registeredCredits -= courses[courseId].credits;
    }
    
    //Covers point 8 - Professors can assign a grade between 0 and 20 to each registeres student
    //Covers point 10 - If the student is approved in 15 credits, an event should be generated
    function assignGrade(uint8 courseId, uint8 grade, address student) external onlyProfessor {
        //Ensures that the course id is valid
        require(courseId >= 0 && courseId < courses.length, "Invalid course ID.");
        //Ensures that the student is registered in course
        require(courses[courseId].registered[student] == true, "Student must be registered in the course.");
        //Ensures that the grade is valid
        require(grade >= 0 && grade <= 20, "Grade must be between 0 and 20.");
        //Ensures that the professor teaches the course
        require(courses[courseId].professor == msg.sender, "Professor must teach the course.");
        
        courses[courseId].grades[student] = grade;
        emit GradeAssigned(msg.sender, student, courseId, grade);
        
        //If approved, updates student's credits, and notifies accordingly - point 10 coverage
        if (grade > 10) {
            uint8 currCredits = students[student].approvedCredits;
            if (currCredits < 15 && currCredits + courses[courseId].credits >= 15) {
                // trigger event letting everyone know the student acquired a degree
                for(uint i = 0; i < courses.length; i++){
                    if (courses[i].professor != address(0)) {
                        emit AcquiredDegree(school, student, courses[i].professor);
                    }
                }
                for(uint i = 0; i < listStudentsAddr.length; i++){
                    emit AcquiredDegree(school, student, listStudentsAddr[i]);
                }
            }
            //Update student's approvedCredits
            students[student].approvedCredits += courses[courseId].credits;
        }
    }
    
    //Covers point 9 - Student can ask for special evaluation if fails the course
    function askForGradeRevision(uint8 courseId) external payable onlyStudent {
        //Ensures that the course id is valid
        require(courseId >= 0 && courseId < courses.length, "Invalid course ID.");
        //Ensures that the student is registered in course
        require(courses[courseId].registered[msg.sender] == true, "Student must be registered in the course.");
        //Ensures that the student failed the course
        require(courses[courseId].grades[msg.sender] >= 0 &&
                courses[courseId].grades[msg.sender] < 10, "Student must fail the course to ask for revision.");
        
        //Studenr pays school 5 Finney
        courses[courseId].gradeChange[msg.sender] = true;
        school.transfer(5 finney);
    }

    //Covers point 9 - professor is able to approve special evaluation
    function approveSpecialEvaluation(address student, uint8 newGrade, uint8 courseId) external payable onlyProfessor{
        require(courses[courseId].professor == msg.sender, "Sender is not professor of given course.");
        require(courses[courseId].registered[student], "Student is not registered on course.");
        require(courses[courseId].gradeChange[student], "Student did not request grade change.");

        courses[courseId].gradeChange[student] = false;
        courses[courseId].grades[student] = newGrade;
        courses[courseId].gradeApprovals = courses[courseId].gradeApprovals + 1;
    }

    //Covers point 9 - school pays the professor 1 finney for every grade approval
    function payExtraApproval(uint8 courseId) external payable onlySchool{
        require(courseId >= 0 && courseId < courses.length, "Invalid course ID.");
        require(courses[courseId].gradeApprovals > 0, "No grade approvals were done.");

        courses[courseId].professor.transfer(courses[courseId].gradeApprovals * 1 finney);
        courses[courseId].gradeApprovals = 0;
    }
}