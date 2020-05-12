pragma solidity ^0.6.0;
contract AcademicService {
    struct Course {
        uint8 credits;
        address professor;
        mapping(address => int) grades;
    }

    struct Student {
        address student;
        uint8 registeredCredits;
        uint8 approvedCredits;
        uint8[] courses;
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

    modifier onlyStudent(){
        require(msg.sender != school, "Sender can't be school.");
        for(uint i = 0; i < courses.length; i++){
            require(courses[i].professor != msg.sender, "Sender can't be a professor.");
        }
        _;
    }

    modifier onlyProfessor(){
        require(msg.sender != school, "Sender can't be school.");
        address professor = address(0);
        for(uint i = 0; i < courses.length; i++){
            if(courses[i].professor == msg.sender){
                professor = courses[i].professor;
            }
        }
        require(professor != address(0), "Sender is not professor.");
        _;
    }

    // This is the constructor whose code is
    // run only when the contract is created.
    constructor(address[] memory studentAddresses) public {
        school = msg.sender;
        start = now;

        uint8 totalCredits = 0;
        uint8[6] memory courseCredits= [3,3,6,6,3,6];
        for(uint i = 0; i < courseCredits.length; i++) {
            require(courseCredits[i] == 6 || courseCredits[i] == 3, "Course credits must be 6 or 3");
            totalCredits = totalCredits + courseCredits[i];
        }

        require(totalCredits > 18, "Total amount of credits must be larger than 18.");
        for(uint i = 0; i<courseCredits.length; i++) {
            courses.push(Course(courseCredits[i],address(0)));
        }

        for(uint i = 0; i < studentAddresses.length; i++) {
            uint8[] memory cs = new uint8[](courses.length);
            students[studentAddresses[i]] = Student(studentAddresses[i],0,0,cs);
        }
    }

    //Covers point 3
    function assignProfessor(uint8 courseId, address professor) external onlySchool{
        //Ensures that the assignment process is being done in the first 2 days of contract creation
        require(now < start + 2 days, "Can only assign professor on the first 2 days of the contract creation.");
        //Checks if courseID is valid
        require(courseId > 0 && courseId < courses.length, "Invalid course ID.");
        //Checks if course does not have a professor associated
        require(courses[courseId].professor == address(0), "Course already has a professor associated.");
        courses[courseId].professor = professor;
    }

    //Covers point 4
    function registerStudents(address[] calldata studentAddresses) external onlySchool {
        //Ensures the student is being registered within the first week
        require(now < start + 1 weeks, "Students can only be registered within the first week of the contract creation." );
        //Checks that student doesn't already exist
        for(uint i = 0; i < studentAddresses.length; i++){
            //if the student does not exists, we register its address
            if(students[studentAddresses[i]].student == address(0)){
                uint8[] memory cs = new uint8[](courses.length);
                students[studentAddresses[i]] = Student(studentAddresses[i],0,0,cs);
            }
        }
    }

    //TODO since uint can only be positive numbers, and the array of courses on a student is a fixed size
    //change the values in the student's courses array so that it's index+1, meaning that 0 is the default value and 1 the course at index 0
    function registerOnCourse(uint8 courseId) external payable onlyStudent{
        uint256 cost;
        require(students[msg.sender].student != address(0), "Student is not registered.");
        require(courseId > 0 && courseId < courses.length, "Invalid course ID.");
        if(students[msg.sender].registeredCredits >= 60) {
            cost = courses[courseId].credits*(0.1 ether);
        } else {
            cost = (courses[courseId].credits - (60-students[msg.sender].registeredCredits))*(0.1 ether);
        }

        if(cost <= 0 || msg.value >= cost) {
            courses[courseId].grades[msg.sender] = -1;
            students[msg.sender].registeredCredits += courses[courseId].credits;
            school.transfer(cost);
        }
    }

    //TODO unregister already assumes indexes in student.courses are +1 in relation to the courses array
    function unregisterCourse(uint8 courseId) external onlyStudent{
        //checks if the time is within the first month of the contract's creation
        require(now < start + 31 days, "Can only unregister during the first month of the contract.");
        require(courseId > 0 && courseId < courses.length, "Invalid course ID.");
        uint8 courseCredits = courses[courseId].credits;
        require(students[msg.sender].registeredCredits - courseCredits >= 0, "Insufficient registered credits on student.");
        require(students[msg.sender].courses[courseId] != 0, "Student is not registered in course");
        //assigns the course inside the student to 0, meaning it's empty
        students[msg.sender].courses[courseId] = 0;
        uint8 currCredits = students[msg.sender].registeredCredits;
        //takes out the credits of the course from which the student unregistered from
        students[msg.sender].registeredCredits = currCredits - courseCredits;
    }
}