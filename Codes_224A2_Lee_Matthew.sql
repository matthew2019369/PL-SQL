/*******
Sample script for creating and populating tables for Assignment 2, ISYS224, 2018
*******/

/**
Drop old Tables
**/
DROP TABLE IF EXISTS T_Repayment;

DROP TABLE IF EXISTS offsetTable;
DROP TABLE IF EXISTS T_Loan;
DROP TABLE IF EXISTS T_Own;
DROP TABLE IF EXISTS T_Customer;

DROP TABLE IF EXISTS T_Account;
DROP TABLE IF EXISTS T_Loan_Type;
DROP TABLE IF EXISTS T_Acc_Type;

/**
Create TablesRepay_Loan
**/

-- Customer --
CREATE TABLE T_Customer (
  CustomerID VARCHAR(10) NOT NULL,
  CustomerName VARCHAR(45) NULL,
  CustomerAddress VARCHAR(45) NULL,
  CustomerContactNo INT NULL,
  CustomerEmail VARCHAR(45) NULL,
  CustomerJoinDate DATETIME NULL,
  PRIMARY KEY (CustomerID));

-- Acc_Type --

CREATE TABLE IF NOT EXISTS T_Acc_Type (
  AccountTypeID VARCHAR(10) NOT NULL,
  TypeName SET('SAV','CHK','LON'),
  TypeDesc VARCHAR(45) NULL,
  TypeRate DECIMAL(4,2) NULL,
  TypeFee DECIMAL(2) NULL,
  PRIMARY KEY (AccountTypeID));
  
-- Account --

CREATE TABLE IF NOT EXISTS T_Account (
  BSB VARCHAR(10) NOT NULL,
  AccountNo VARCHAR(10) NOT NULL,
  AccountBal DECIMAL(10) NULL,
  AccountType VARCHAR(10) NOT NULL,
  PRIMARY KEY (BSB, AccountNo),
    FOREIGN KEY (AccountType)
    REFERENCES T_Acc_Type(AccountTypeID));


-- Loan_Type --

CREATE TABLE IF NOT EXISTS T_Loan_Type (
  LoanTypeID VARCHAR(10) NOT NULL,
  Loan_TypeName SET('HL','IL','PL'),
  Loan_TypeDesc VARCHAR(45) NULL,
  Loan_TypeMInRate DECIMAL(4,2) NULL,
  PRIMARY KEY (LoanTypeID));
  
-- Loan --

CREATE TABLE IF NOT EXISTS T_Loan (
  LoanID VARCHAR(10) NOT NULL,
  LoanRate DECIMAL(4,2) NULL,
  LoanAmount DECIMAL(8) NULL,
  Loan_Type VARCHAR(10) NOT NULL,
  Loan_AccountBSB VARCHAR(10) NOT NULL,
  Loan_AcctNo VARCHAR(10) NOT NULL,
  PRIMARY KEY (LoanID),
	FOREIGN KEY (Loan_Type)
    REFERENCES T_Loan_Type (LoanTypeID),
    FOREIGN KEY (Loan_AccountBSB , Loan_AcctNo)
    REFERENCES T_Account (BSB, AccountNo));

-- Repayment --

CREATE TABLE IF NOT EXISTS T_Repayment (
  RepaymentNo int NOT NULL AUTO_INCREMENT,
  Repayment_LoanID VARCHAR(10) NOT NULL,
  RepaymentAmount DECIMAL(6) NULL,
  RepaymentDate DATETIME NULL,
  PRIMARY KEY (RepaymentNo),
    FOREIGN KEY (Repayment_LoanID)
    REFERENCES T_Loan (LoanID));

-- Own --

CREATE TABLE IF NOT EXISTS T_Own (
  Customer_ID VARCHAR(10) NOT NULL,
  Account_BSB VARCHAR(10) NOT NULL,
  Account_No VARCHAR(10) NOT NULL,
  PRIMARY KEY (Customer_ID, Account_BSB, Account_No),
    FOREIGN KEY (Customer_ID)
    REFERENCES T_Customer (customerID),
    FOREIGN KEY (Account_BSB, Account_No)
    REFERENCES T_Account (BSB, AccountNo));
       
       #this table is created for task 4
create table offsetTable (
	offsetDate date not null,
    offsetBSB varchar(10) not null,
    offsetAcctNo varchar(10) not null,
    offsetAmount decimal(11,2)  not null,
    primary key (offsetBSB, offsetAcctNo, offsetDate),
    FOREIGN KEY ( offsetBSB, offsetAcctNo)
    REFERENCES T_Loan ( Loan_AccountBSB, Loan_AcctNo));


/* 
Populate Tables
*/


INSERT INTO T_Customer VALUES ('C1','Adam','AdamHouse','234567891','aMail','2015-10-10');
INSERT INTO T_Customer VALUES ('C2','Badshah','BadshahPalace','234567892','bMail','2015-10-11');
INSERT INTO T_Customer VALUES ('C3','Chandni','ChandniBar','234567893','cMail','2015-10-12');

INSERT INTO T_Acc_Type VALUES ('AT1','SAV','Savings','0.1','15');
INSERT INTO T_Acc_Type VALUES ('AT2','CHK','Checking','0.2','16');
INSERT INTO T_Acc_Type VALUES ('AT3','LON','Loan','0','17');

INSERT INTO T_Account VALUES ('BSB1','Acct1','10.00','AT1');
INSERT INTO T_Account VALUES ('BSB2','Acct2','11.00','AT3');
INSERT INTO T_Account VALUES ('BSB3','Acct3','-5000','AT3');
INSERT INTO T_Account VALUES ('BSB3','Acct4','-7000','AT3');
INSERT INTO T_Account VALUES ('BSB1','Acct5','10.00','AT1');
INSERT INTO T_Account VALUES ('BSB1','Acct6','10.00','AT1');

INSERT INTO T_Loan_Type VALUES ('LT1','HL','Home Loan','0.01');
INSERT INTO T_Loan_Type VALUES ('LT2','IL','Investment Loan','0.02');
INSERT INTO T_Loan_Type VALUES ('LT3','PL','Personal Loan','0.03');

INSERT INTO T_Loan VALUES ('L1','0.05','5000.00','LT3','BSB3','Acct4');
INSERT INTO T_Loan VALUES ('L2','0.02','16200.00','LT2','BSB2','Acct2');
INSERT INTO T_Loan VALUES ('L3','0.03','670500.00','LT1','BSB3','Acct3');

INSERT INTO T_Repayment (Repayment_LoanID, RepaymentAmount, RepaymentDate)
       	VALUES ('L1','1.00','2017-10-10');
INSERT INTO T_Repayment  (Repayment_LoanID, RepaymentAmount, RepaymentDate)
        VALUES ('L2','2.00','2018-02-11');
INSERT INTO T_Repayment  (Repayment_LoanID, RepaymentAmount, RepaymentDate)
        VALUES ('L3','2.00','2018-02-11');

INSERT INTO T_Own VALUES ('C1','BSB2','Acct2');
INSERT INTO T_Own VALUES ('C2','BSB3','Acct3');
INSERT INTO T_Own VALUES ('C3','BSB3','Acct4');
INSERT INTO T_Own VALUES ('C1','BSB3','Acct4');
INSERT INTO T_Own VALUES ('C1','BSB1','Acct1');
INSERT INTO T_Own VALUES ('C2','BSB1','Acct5');
INSERT INTO T_Own VALUES ('C3','BSB1','Acct6');



/**
End Script
**/

/*
	Task 2
*/

delimiter //
drop procedure if exists Repay_Loan //
create procedure Repay_Loan(in from_BSB varchar(10), in from_account varchar(10), in to_loan varchar(10),in amount double)
begin
	#error handling variable for no row found
	Declare no_row_found int default 0;
    
    #variable to store how much you have in your from_account
	Declare saving_amount double;
    
    #find the corresponding loanBSB and  accountNo attached by the loanID
    Declare loan_BSB varchar(10);
    Declare loan_Acc varchar(10);
    Declare loan_left double;
    
    Declare commonOwner int default 0;#store the number of common owner of both accounts
    
    declare continue handler for not found set no_row_found =1;
    
    #select the balance from the saving account
    select AccountBal into saving_amount 
    from T_Account
    where BSB=from_BSB and AccountNo = from_account;  
    
    #select the corresponding loanAcct for loanID
    select BSB, AccountNo, AccountBal into loan_BSB, loan_Acc, loan_left
    from T_Loan, T_Account
    where (Loan_AccountBSB=BSB and Loan_AcctNo=AccountNo) and
    to_loan = LoanID;
    
    if(no_row_found) then
		signal sqlstate '45000' set message_text='accounts not found';
	end if;
     
     #this query finds the number of CustomerID which is the owner of both accounts-loan account and from_acc
	select count(Customer_ID) into commonOwner
	from T_Own
	where Account_BSB=from_BSB and
	Account_No=from_account and 
	(Customer_ID in (select Customer_ID 
	from T_Own
	where Account_BSB=loan_BSB
	and Account_No = loan_Acc));
    
    
	if(commonOwner=0) then#raise an error if no common Owners found
		signal sqlstate '45000' set message_text = 'the owner of account and owner of loan account are not matched';
    elseif (amount >saving_amount) then 
		signal sqlstate '45000' set message_text = 'not enough balance to transfer from account';
	else 
    
		#select concat('Before transcation: ',from_BSB,' ',from_account, 'has balance: $',saving_amount);
		#select concat('Before transcation: ',loan_BSB,' ',loan_Acc, 'has loan left: $',loan_left);
        
		update T_Account
        set AccountBal = AccountBal+amount
        where BSB=loan_BSB and AccountNo=loan_Acc;
        
        update T_Account
        set AccountBal = saving_amount-amount
        where BSB=from_BSB and AccountNo=from_account;
        
        #select concat('After transcation: ',from_BSB,' ',from_account, 'has balance: $',saving_amount-amount);
		#select concat('After transcation: ',loan_BSB,' ',loan_Acc, 'has loan left: $',loan_left-amount);
        
        INSERT INTO T_Repayment (Repayment_LoanID, RepaymentAmount, RepaymentDate)
       	VALUES (to_loan,amount,NOW());
        
	end if;
end //
delimiter ;
select * from T_Repayment;
select * from T_Account;
select * from T_Loan;
call Repay_Loan('BSB1','Acct1','L3','5.00');#customerID are different
call Repay_Loan('BSB1','Acct1','L2','4.00');#successful transaction
call Repay_Loan('BSB1','Acct1','L2','2000.00');#amount is more than savingBalance

/*
end of task 2
*/

/*
task 3
*/
delimiter //
drop trigger if exists task3Trigger //
create trigger task3Trigger
	before insert on T_Loan#validate after insertion
    for each row
begin
	declare v_finished boolean default 0;#to track end of cursor
    declare raiseError int default 0;
    
    declare temp_CID varchar(10); #used to indicate current customerID in the cursor	
    
    declare temp_homeLoan int;#used to indicate number of home loans possesed by a customerID
    declare personalLoan_count int;#used to indicate number of home loans possesed by a customerID
    declare temp_totalLoanAmt decimal(11,2);#used to indicate total aamount of all loans possessed by a customerID
    declare temp_IndividualLoan int; #used to indicate number of individual loans possessed by a customerID
    declare temp_totalLoan int;#used to indicate number of total loans possessed by a customerID
    
    declare msg varchar(100); #set error message
        
    declare owner_rec cursor for#save all customerID linked to the Account just inserted to the T_Loan
		select customer_ID
        from T_Account, T_Own
        where (BSB=Account_BSB and
        AccountNo = Account_No) and 
        (BSB=new.Loan_AccountBSB and 
        AccountNo= new.Loan_AcctNo);
	declare continue handler for not found set v_finished=1;
    
    open owner_rec;
    repeat 
		fetch owner_rec into temp_CID;
        
			if(not v_finished) then
				set temp_homeLoan =0;
                set personalLoan_count=0;
                set temp_totalLoanAmt = 0;
				set temp_IndividualLoan = 0;
                set temp_totalLoan = 0;
                
                set temp_totalLoan = totalLoan(temp_CID)+1; #function used to calculate the total number of loans to a customerID
				set temp_homeLoan= numberOfHomeLoan(temp_CID);
                set personalLoan_count= numberOfPersonalLoan(temp_CID);
				set temp_totalLoanAmt = totalLoanAmount(temp_CID)+new.LoanAmount;# function used to calcuate the total Amount of all loans for a customerID
                #function used to calculate the number of  individual loans to a customerID
				set temp_IndividualLoan = CountOfIndividualAccount(temp_CID)+isIndividualAccount(new.Loan_AccountBSB, new.Loan_AcctNo) ;
        
                if(new.Loan_Type='LT1') then 
					set temp_homeLoan= temp_homeLoan +1;
				elseif (new.Loan_Type='LT3') then
					set personalLoan_count= personalLoan_count+1;
				end if;
                
                if (temp_totalLoan >8) then
					set raiseError =1;
					set msg = 'maximum number of loans is 8 ';
                    set v_finished=1;
				elseif(temp_homeLoan>3) then
					set raiseError =1;
					set msg = 'maximum(3) of home loans is reached ! ';
                    set v_finished=1;
				elseif (personalLoan_count>1) then
					set raiseError =1;
					set msg = 'maximum(1) of personal loans is reached ! ';
                    set v_finished=1;
				elseif (temp_totalLoanAmt>10000000.00) then
					set raiseError =1;
					set msg = 'adding new loan exceeds maximum loan amount $10000000.00 ';
                    set v_finished=1;
				elseif (temp_IndividualLoan >5) then
					set raiseError =1;
					set msg = 'maximum number of individual loans is 5.';
                    set v_finished=1;
				end if ;
                
				set temp_CID='';
            end if ;
	 until v_finished
	end repeat;
    close owner_rec;
    
    if (raiseError=1) then
		signal sqlstate '45000' set message_text =msg;
	end if ;
end
//
delimiter ;

delimiter //
#function helps to the total number of loans for a customerID which tells you how many loans belong to that customerID
drop function if exists totalLoan //
create function totalLoan(CID varchar(10))
	returns int
    deterministic
begin

	declare result int default 0;
    
	select count(*) into result
	from T_Account, T_Own, T_Loan
	where (BSB = Account_BSB and
        AccountNo=Account_No and
        BSB = Loan_AccountBSB and 
        AccountNo = Loan_AcctNo) and 
        Customer_ID=CID;
    return result;
end
//
delimiter ;

delimiter //
##function help to find the number of homeLoans for CID
drop function if exists numberOfHomeLoan //
create function numberOfHomeLoan(CID varchar(11))
	returns int(11)
    deterministic
begin
	declare result int default 0;
    
	select count(*) into result
				from T_Account, T_Own, T_Loan
				where (BSB = Account_BSB and
				AccountNo=Account_No and
				BSB = Loan_AccountBSB and 
				AccountNo = Loan_AcctNo) and
				(Loan_Type ='LT1'  and Customer_ID= CID);
    
    return result;
end 
//
delimiter ;

delimiter //
#find out the number of personal loan
drop function if exists numberOfPersonalLoan //
create function numberOfPersonalLoan(CID varchar(11))
	returns int(11)
    deterministic
begin
	declare result int default 0;
	select count(*) into result
				from T_Account, T_Own, T_Loan
				where (BSB = Account_BSB and
				AccountNo=Account_No and
				BSB = Loan_AccountBSB and 
				AccountNo = Loan_AcctNo) and
				(Loan_Type ='LT3'  and Customer_ID= CID);
    
    return result;
end 
//
delimiter ;

delimiter //
#check the totalLoanAmount
drop function if exists totalLoanAmount //
create function totalLoanAmount(CID varchar(11))
	returns decimal(11,2)
    deterministic
begin
	declare result int default 0;
	select sum(LoanAmount) into result
	from T_Account, T_Own, T_Loan
	where BSB = Account_BSB and
        AccountNo=Account_No and 
        BSB = Loan_AccountBSB and 
        AccountNo = Loan_AcctNo and
        Customer_ID=CID;
    return result;
end 
//
delimiter ;


delimiter //
#check if the account is an individualAccount or not
# yes return 1, no return 0
drop function if exists isIndividualAccount //
create function isIndividualAccount(loanBSB varchar(10), loanAcctNo varchar(10))
	returns int
    deterministic
begin
	declare result int default 0;
	select count(Customer_ID) into result
	from T_Account, T_Own, T_Loan
	where BSB = Account_BSB and
        AccountNo=Account_No and 
        BSB = Loan_AccountBSB and 
        AccountNo = Loan_AcctNo and
        BSB=loanBSB and AccountNo = loanAcctNo;
        
	if(result=1) then 
		return 1;
	end if ;
    return 0;
end 
//
delimiter ;

delimiter //
#this function returns the number of individaul account for a customerID
drop function if exists CountOfIndividualAccount //
CREATE  FUNCTION CountOfIndividualAccount(CID varchar(11)) 
	RETURNS int(11)
    DETERMINISTIC
begin 
	declare v_finished int default 0;
    declare tempCount int;#keep tracking of number of customerID(s) attached for an account
    
	declare result int default 0;#store number of individual accounts for a customerID
    
    declare temp_BSB varchar(10);#store BSB temporarily
    declare temp_acc varchar(10);#store account number temporarily
    
	declare loan_AcctRec cursor for
		select BSB, AccountNo
        from T_Account, T_Own, T_Loan
        where (BSB = Account_BSB and
        AccountNo=Account_No and 
        BSB=Loan_AccountBSB and 
        AccountNo = Loan_AcctNo) and 
        Customer_ID=CID;
	declare continue handler for not found set v_finished=1;
    
    open loan_AcctRec;
    myLoop : loop
		set tempCount =0;
		fetch loan_AcctRec into temp_BSB, temp_acc;
        
        if (v_finished) then
			leave myLoop;
		end if;
        # find out the number of customerID attached to that account related to CID
        select count(Customer_ID) into tempCount
        from T_Own 
        where Account_BSB=temp_BSB and 
        Account_No = temp_acc;
        
        #tempCount =1 means only one customerID attached
        if(tempCount =1) then
			set result = result+1;
		end if ;
        
    end loop;
    close loan_AcctRec;
    
    return result;
end
//
delimiter ;

/*
test case for task 3
*/

# test cases for homeLoan insertion
INSERT INTO T_Account VALUES ('BSB10','Acct1','10.00','AT3'); # test case for first homeloan for C1
INSERT INTO T_Own VALUES ('C1','BSB10','Acct1');# test case for first homeloan for C1
INSERT INTO T_Loan VALUES ('L10','0.05','5000.00','LT1','BSB10','Acct1');#first homeloan for C1 [success]


INSERT INTO T_Account VALUES ('BSB11','Acct1','10.00','AT3');# test case for second homeloan for C1
INSERT INTO T_Own VALUES ('C1','BSB11','Acct1');
INSERT INTO T_Loan VALUES ('L11','0.05','5000.00','LT1','BSB11','Acct1');#second homeloan for C1 [success]


INSERT INTO T_Account VALUES ('BSB12','Acct1','10.00','AT3');#test case for third homeloan for C1
INSERT INTO T_Own VALUES ('C1','BSB12','Acct1');
INSERT INTO T_Loan VALUES ('L12','0.05','5000.00','LT1','BSB12','Acct1');#third homeloan for C1 [success]


INSERT INTO T_Account VALUES ('BSB13','Acct1','10.00','AT3');#test case for fourth homeloan for C1
INSERT INTO T_Own VALUES ('C1','BSB13','Acct1');
INSERT INTO T_Loan VALUES ('L13','0.05','5000.00','LT1','BSB13','Acct1');# fourth homeloan for C1 [fail]

#test cases for personal loan insertion
INSERT INTO T_Account VALUES ('BSB14','Acct1','10.00','AT3');#test case for second personal loan for C1
INSERT INTO T_Own VALUES ('C1','BSB14','Acct1');
INSERT into T_Loan values ('L14','0.05','5000.00','LT3','BSB14', 'Acct1');# second personal loan for C1 [fail]

#test cases for individual loan 
INSERT INTO T_Account VALUES ('BSB20','Acct1','10.00','AT3');#test case for fifth individual loan for C1
INSERT INTO T_Own VALUES ('C1','BSB20','Acct1');
INSERT into T_Loan values ('L20','0.05','5000.00','LT2','BSB20', 'Acct1');# fifth  individual loan for C1 [success]

INSERT INTO T_Account VALUES ('BSB21','Acct1','10.00','AT3');#test case for sixth individual loan for C1
INSERT INTO T_Own VALUES ('C1','BSB21','Acct1');
INSERT into T_Loan values ('L21','0.05','5000.00','LT2','BSB20', 'Acct1');# sixth individual loan for C1 [fail]

#test cases for maximum loan 
INSERT INTO T_Account VALUES ('BSB31','Acct1','10.00','AT3');#test case for seventh loan for C1
INSERT INTO T_Own VALUES ('C1','BSB31','Acct1');
INSERT INTO T_Own VALUES ('C2','BSB31','Acct1');
INSERT into T_Loan values ('L31','0.05','5000.00','LT2','BSB31', 'Acct1');# seventh loan for C1 [sucess]

INSERT INTO T_Account VALUES ('BSB32','Acct1','10.00','AT3');#test case for eighith loan for C1
INSERT INTO T_Own VALUES ('C1','BSB32','Acct1');
INSERT INTO T_Own VALUES ('C2','BSB32','Acct1');
INSERT into T_Loan values ('L32','0.05','5000.00','LT2','BSB32', 'Acct1');# eighth loan for C1 [sucess]

INSERT INTO T_Account VALUES ('BSB33','Acct1','10.00','AT3');#test case for nineth loan for C1
INSERT INTO T_Own VALUES ('C1','BSB33','Acct1');
INSERT INTO T_Own VALUES ('C2','BSB33','Acct1');
INSERT into T_Loan values ('L33','0.05','5000.00','LT2','BSB33', 'Acct1');# nineth loan for C1 [fail]

#test cases for totalAmount 
INSERT INTO T_Account VALUES ('BSB41','Acct1','10.00','AT3');# test case for  maximum loan amount for C2
INSERT INTO T_Own VALUES ('C2','BSB41','Acct1');
INSERT INTO T_Loan VALUES ('L41','0.05','10000000.00','LT1','BSB41','Acct1');#second hmaximum loan amount for C2 [fail]


/*
end of task 3
*/

/*
task 4
*/

delimiter //
drop procedure if exists interestCalculator //
create procedure interestCalculator (in startingDate date, in endDate date ,in loanID varchar(11))
begin
    declare not_found_row int default 0;
    declare temp_offsetAmount decimal default 0;
    declare temp_repaymentAmount decimal default 0 ;
    declare interest decimal(11,2);
    declare tempBSB varchar(10);
    declare tempAcctNo varchar(10);
    declare interestRate decimal(10,8);
    declare loanBalance decimal(11,2);
    declare continue handler for not found set not_found_row =1;
    
    select BSB, AccountNo, LoanRate,AccountBal  into tempBSB, tempAcctNo, interestRate, LoanBalance
    from T_Account, T_Loan
    where BSB=Loan_AccountBSB and
    AccountNo = Loan_AcctNo and 
    T_Loan.LoanID=loanID;
    
    set interest =0;
    if(not_found_row) then
		signal sqlstate '45000' set message_text = 'no account found for that loanID';
	end if;
    
    select subDate(endDate, interval 1 day) into endDate;
    
    set temp_offsetAmount =getOffset(endDate,tempBSB,tempAcctNo);
    
    while (datediff(endDate, startingDate)>0) do
        set temp_offsetAmount =getOffset(endDate,tempBSB,tempAcctNo);
        set  interest = interest+ ((loanBalance+temp_offsetAmount)*interestRate/365);
        set loanBalance=loanBalance-getRepayment(endDate,loanID);
        select subDate(endDate, interval 1 day) into endDate;
    end while;
    
    select concat('Interest for ', loanID, ' is ',interest ) as 'result';
end
//
delimiter ;

delimiter // 
drop function if exists getOffset //
#get offset amount for a account and bsb and a date 
create function getOffset(d date, bsb varchar(10), acct varchar(10))
	returns decimal(11,2)
    deterministic
    begin
    declare row_not_found int default 0;
	declare result decimal(11,2);
    declare continue handler for not found set row_not_found =1;
    
    select offsetAmount into result
    from offsetTable where 
    offsetBSB=bsb and 
    offsetAcctNo = acct and 
    datediff(d,offsetDate)>=0
    order by offsetDate desc
    limit 1;
    
    if (row_not_found) then
		return 0;
	else 
		return result;
    end if;
    end 
    //
delimiter ;

delimiter // 
#getRepayment for a data and loanID
drop function if exists getRepayment //

create function getRepayment(d date, loan varchar(10))
	returns decimal(11,2)
    deterministic
begin
    declare row_not_found int default 0;
	declare result decimal(11,2);
    declare continue handler for not found set row_not_found =1;
    
    select RepaymentAmount into result
    from T_Repayment 
    where RepaymentDate=d and
    Repayment_LoanID = loan;
    
    if (row_not_found) then
		return 0;
    end if;
    return result;
end 
//
delimiter ;

/*
test case for task 4
*/

#Test case of simple calculator example for task 4

INSERT INTO T_Customer VALUES ('C4','matthew','lee','1234567','dMail','2015-10-12');
INSERT INTO T_Account VALUES ('BSB50','Acct1','-60000.00','AT3');
INSERT INTO T_Own VALUES ('C4','BSB50','Acct1');
INSERT INTO T_Loan VALUES ('L50','0.05','670500.00','LT1','BSB50','Acct1');
INSERT INTO T_Repayment  (Repayment_LoanID, RepaymentAmount, RepaymentDate)
        VALUES ('L50','5000','2018-10-20');
INSERT INTO T_Repayment  (Repayment_LoanID, RepaymentAmount, RepaymentDate)
        VALUES ('L50','3000','2018-10-18');
        
INSERT INTO T_Repayment  (Repayment_LoanID, RepaymentAmount, RepaymentDate)
        VALUES ('L50','5000','2018-09-26');
        
        
        
INSERT INTO offsetTable  values ('2018-10-21','BSB50','Acct1',7000);
INSERT INTO offsetTable  values ('2018-10-14','BSB50','Acct1',5000);
INSERT INTO offsetTable  values ('2018-10-07','BSB50','Acct1',8000);
INSERT INTO offsetTable  values ('2018-09-30','BSB50','Acct1',6000);
INSERT INTO offsetTable  values ('2018-09-23','BSB50','Acct1',12000);


call interestCalculator('2018-09-24','2018-10-25', 'L50');


#March test case for task 4
INSERT INTO T_Customer VALUES ('C5','Yvonne','Lam','12344','dMail','2015-10-12');
INSERT INTO T_Account VALUES ('BSB51','Acct1','-60000.00','AT3');
INSERT INTO T_Own VALUES ('C5','BSB51','Acct1');
INSERT INTO T_Loan VALUES ('L51','0.05','60000.00','LT1','BSB51','Acct1');
INSERT INTO T_Repayment  (Repayment_LoanID, RepaymentAmount, RepaymentDate)
        VALUES ('L51','6000','2018-03-20');
INSERT INTO T_Repayment  (Repayment_LoanID, RepaymentAmount, RepaymentDate)
        VALUES ('L51','7000','2018-03-18');
        
INSERT INTO T_Repayment  (Repayment_LoanID, RepaymentAmount, RepaymentDate)
        VALUES ('L51','5000','2018-02-26');
        
INSERT INTO offsetTable  values ('2018-03-21','BSB50','Acct1',6000);
INSERT INTO offsetTable  values ('2018-03-14','BSB50','Acct1',5000);
INSERT INTO offsetTable  values ('2018-03-07','BSB50','Acct1',8000);
INSERT INTO offsetTable  values ('2018-02-28','BSB50','Acct1',6000);


call interestCalculator('2018-02-24','2018-03-25', 'L51');
        
#May test case for task 4 
INSERT INTO T_Customer VALUES ('C6','Vicky','Su','123444','dMail','2015-10-12');
INSERT INTO T_Account VALUES ('BSB52','Acct1','-60000.00','AT3');
INSERT INTO T_Own VALUES ('C6','BSB52','Acct1');
INSERT INTO T_Loan VALUES ('L52','0.05','60000.00','LT1','BSB52','Acct1');
INSERT INTO T_Repayment  (Repayment_LoanID, RepaymentAmount, RepaymentDate)
        VALUES ('L52','6000','2018-05-20');
INSERT INTO T_Repayment  (Repayment_LoanID, RepaymentAmount, RepaymentDate)
        VALUES ('L52','7000','2018-05-18');
        
INSERT INTO T_Repayment  (Repayment_LoanID, RepaymentAmount, RepaymentDate)
        VALUES ('L52','5000','2018-04-26');
        
INSERT INTO offsetTable  values ('2018-05-21','BSB52','Acct1',7000);
INSERT INTO offsetTable  values ('2018-05-14','BSB52','Acct1',5000);
INSERT INTO offsetTable  values ('2018-04-26','BSB52','Acct1',12000);     


call interestCalculator('2018-04-24','2018-05-25', 'L52');

#August test case for task 4
INSERT INTO T_Customer VALUES ('C7','ricky','Tam','123444','dMail','2015-10-12');
INSERT INTO T_Account VALUES ('BSB53','Acct1','-60000.00','AT3');
INSERT INTO T_Own VALUES ('C7','BSB53','Acct1');
INSERT INTO T_Loan VALUES ('L53','0.05','60000.00','LT1','BSB53','Acct1');
INSERT INTO T_Repayment  (Repayment_LoanID, RepaymentAmount, RepaymentDate)
        VALUES ('L53','6000','2018-08-20');
INSERT INTO T_Repayment  (Repayment_LoanID, RepaymentAmount, RepaymentDate)
        VALUES ('L53','7000','2018-08-18');
INSERT INTO T_Repayment  (Repayment_LoanID, RepaymentAmount, RepaymentDate)
        VALUES ('L53','5000','2018-07-26');
        
INSERT INTO offsetTable  values ('2018-08-21','BSB52','Acct1',6000);
INSERT INTO offsetTable  values ('2018-08-14','BSB52','Acct1',5000);
INSERT INTO offsetTable  values ('2018-07-26','BSB52','Acct1',6000);     

#Test case called 

call interestCalculator('2018-07-24','2018-08-25', 'L53');

/*
end of task 4
*/