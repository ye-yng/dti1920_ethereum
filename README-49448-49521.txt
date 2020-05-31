/**
 * @author João David n49448, Ye Yang n49521
 */
Testing the program:
The constructor of the contract receives a list of students which can be added through the remix ide with the following syntax:
	- ["0xaddress",...] or []

For each one of the functions, we must make sure to be executing the function using the correct account, 
	say for example a professor address accessing the assignGrade function.

To prevent an incorrect user from accessing a certain service, 
	modifiers were placed to ensure that an accessing account is either a professor, school or student.

Functions Explanation:
	- assignProfessor(uint8 courseId, address payable professor) external onlySchool
		courseID: The course where the professor will be teaching
		professor: The theacher's address
		
	- registerStudents(address payable[] calldata studentAddresses) external onlySchool
		studentAddresses: Array of addresses that will be assigned as students, similiar to the constructor argument
	
	- registerOnCourse(uint8 courseId) external payable onlyStudent
		courseId: Registers the function caller in the course with ID courseId
	
	- unregisterCourse(uint8 courseId) external onlyStudent
		courseId: Unregisters the function caller from the course with ID courseId
		
	- assignGrade(uint8 courseId, uint8 grade, address student) external onlyProfessor
		courseId: The course id where the grade will be assigned
		grade: The grade being assigned
		student: The student's address, who will get the grade
	
	- askForGradeRevision(uint8 courseId) external payable onlyStudent
		courseId: The couse in which the function caller student will ask for grade revision
	
	- approveSpecialEvaluation(address student, uint8 newGrade, uint8 courseId) external payable onlyProfessor
		student: Student that will his grade revision request approved
		newGrade: New grade assigned
		courseId: The course where the grade revision was requested
		
	- rejectSpecialEvaluation(address student, uint8 courseId) external payable onlyProfessor
		student: Student that will his grade revision request rejected
		courseId: The course where the grade revision was requested

	- payExtraApproval(uint8 courseId) external payable onlySchool
		Pays the courseIDs professor the value according to the number of grade revisions done

Gas costs:
	- Data structures
		Most of our data has been stored in mappings as they're less heavy in gas costs when compared to arrays 
			and there was no need to iterate over the values which is one of the benefits of using arrays.
			
	-Modifiers
		Since all functions use modifiers, they have the same execution cost associated to a modifier.
		Both onlySchool() and onlyStudent() modifiers have a fixed execution cost, 
			while onlyProfessor() has a cost relative to the number of hardcoded courses on deployment.
			
	-Deployment
		Gas costs on deployment are quite higher than function calls as it uploads the entire contract to the blockchain. 
		The execution cost is dependent on the size of the initial array given on input.
		The larger the array of student addresses, the more computation is needed to add the students to the contract and thus increasing the execution cost.
		Since the array of courses is hardcoded within the code, gas costs related to these are constant.
	
	- assignProfessor
		Gas costs on this function are relatively low, as it only executes a few simple boolean logic verification, 
		finishing with a value assignment leaving the final execution cost low.
		
	- registerStudents
		The cost of this function is relative to the length of the studentAddresses array given. 
		The larger the array the higher the cost (more cycles run in for and thus more operations).

	- registerOnCourse
		If the given address matches all the require blocks, then the gas cost cost of this function is constant, varying only on the if condition.
		If a student has more than 18 credits, then more computation is needed to be done, thus increasing gas price.
		If the any require statement is not met, the cost decreases as less instructions are computed.
	
	- unregisterCourse
		Similar to the previous function, the require statement cost also applies, however the cost is always constant if the require statements all verify.

	- assignGrade
		The cost of this functions varies according to the grade given by a professor.
		If it is a passing grade (higher than 10) then extra computation is needed to give the credits to a student for passing the course, thus increasing execution cost.

	- askForGradeRevision/approveSpecialEvaluation/payExtraApproval
		These last 3 functions all have a constant transaction and execution cost if all require statements are met 
			as there are no extra instructions and conditional blocks that may influence the number of operations needed to be computed.