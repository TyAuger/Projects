--B.U. CS669 Project
--Tyler Auger
--
--DROP CYA
ROLLBACK;
--DROP TRIGGER nonneg_trg ON Account_balance;
DROP TRIGGER valid_date_trg ON Reservation;
DROP TRIGGER valid_add_account_trg ON Account;
DROP TRIGGER valid_add_club_group_trg ON Club_or_Group;
DROP TRIGGER check_creator_genre_onFile_trg ON Content;
DROP TRIGGER valid_rental_trg ON Rent;
DROP TABLE Account_balance;
DROP TABLE Reservation;
DROP TABLE Room;
DROP TABLE Club_or_Group;
DROP TABLE Rent;
DROP TABLE Content;
DROP TABLE Games;
DROP TABLE Literature;
DROP TABLE Music;
DROP TABLE Content_type;
DROP TABLE Physical;
DROP TABLE Digital;
DROP TABLE Medium_type;
DROP TABLE Genre;
DROP TABLE Author_or_Artist;
DROP TABLE New_fine;
DROP FUNCTION NewFineFunction();
DROP TABLE Account;
DROP SEQUENCE account_seq;
DROP SEQUENCE account_balance_seq;
DROP SEQUENCE club_group_seq;
DROP SEQUENCE room_seq;
DROP SEQUENCE author_artist_seq;
DROP SEQUENCE genre_seq;
DROP SEQUENCE medium_type_seq;
DROP SEQUENCE content_type_seq;
DROP SEQUENCE content_seq;
DROP SEQUENCE balance_change_seq;
DROP SEQUENCE rental_seq;
DROP SEQUENCE reservation_seq;

-- Table and Sequence By Entity Creation
CREATE TABLE Account (
account_id DECIMAL(12) NOT NULL PRIMARY KEY,
first_name VARCHAR(32) NOT NULL,
last_name VARCHAR(32) NOT NULL,
membership_start DATE NOT NULL
	);
CREATE SEQUENCE account_seq START WITH 1;

CREATE TABLE Account_balance (
fine_id DECIMAL(12) NOT NULL PRIMARY KEY,
balance DECIMAL(12,2) NOT NULL,
account_id DECIMAL(12) NOT NULL,
FOREIGN KEY(account_id) REFERENCES Account(account_id)
	);
CREATE SEQUENCE account_balance_seq START WITH 1;

CREATE TABLE Club_or_Group (
club_group_id DECIMAL(12) NOT NULL PRIMARY KEY,
description VARCHAR(764) NOT NULL,
club_name VARCHAR(64)  NOT NULL,
account_id DECIMAL(12) NOT NULL,
FOREIGN KEY(account_id) REFERENCES Account(account_id)
	);
CREATE SEQUENCE club_group_seq START WITH 1;
CREATE TABLE Room (
room_id DECIMAL(4) NOT NULL PRIMARY KEY
	);
CREATE SEQUENCE room_seq START WITH 1;
CREATE TABLE Reservation (
reservation_id DECIMAL(12) NOT NULL PRIMARY KEY,
club_group_id DECIMAL(12) NOT NULL,
room_id DECIMAL(4) NOT NULL,
reservation_date DATE NOT NULL,
FOREIGN KEY(club_group_id) REFERENCES Club_or_Group(club_group_id),
FOREIGN KEY(room_id) REFERENCES Room(room_id)
	);
CREATE SEQUENCE reservation_seq;
CREATE TABLE Author_or_Artist (
author_artist_id DECIMAL(12) NOT NULL PRIMARY KEY,
first_name VARCHAR(32),
last_name VARCHAR(32) NOT NULL
	);
CREATE SEQUENCE author_artist_seq START WITH 1;
CREATE TABLE Genre (
genre_id DECIMAL(12) NOT NULL PRIMARY KEY,
genre_type VARCHAR(32) NOT NULL
	);
CREATE SEQUENCE genre_seq START WITH 1;
CREATE TABLE Medium_type (
medium_type_id DECIMAL(12) NOT NULL PRIMARY KEY,
medium_type VARCHAR(32)
	);
CREATE TABLE physical (
medium_type_id DECIMAL(12) NOT NULL PRIMARY KEY,
FOREIGN KEY(medium_type_id) REFERENCES Medium_type(medium_type_id)
	);
CREATE TABLE digital (
medium_type_id DECIMAL(12) NOT NULL PRIMARY KEY,
FOREIGN KEY(medium_type_id) REFERENCES Medium_type(medium_type_id)
	);
CREATE SEQUENCE medium_type_seq START WITH 1;
CREATE TABLE Content_type (
content_type_id DECIMAL(12) NOT NULL PRIMARY KEY,
content_type VARCHAR(32) NOT NULL
	);
CREATE TABLE Literature (
content_type_id DECIMAL(12) NOT NULL PRIMARY KEY,
FOREIGN KEY(content_type_id) REFERENCES Content_type(content_type_id)
	);
CREATE TABLE Music (
content_type_id DECIMAL(12) NOT NULL PRIMARY KEY,
FOREIGN KEY(content_type_id) REFERENCES Content_type(content_type_id)
	);
CREATE TABLE Games (
content_type_id DECIMAL(12) NOT NULL PRIMARY KEY,
FOREIGN KEY(content_type_id) REFERENCES Content_type(content_type_id)
	);
CREATE SEQUENCE content_type_seq START WITH 1;
CREATE TABLE Content (
ISBN_id DECIMAL(13) NOT NULL PRIMARY KEY,
content_name VARCHAR(64) NOT NULL,
number_copies DECIMAL(3) NOT NULL,
content_type_id DECIMAL(12) NOT NULL,
author_artist_id DECIMAL(12) NOT NULL,
genre_id DECIMAL(12) NOT NULL,
medium_type_id DECIMAL(12) NOT NULL,
FOREIGN KEY(content_type_id) REFERENCES Content_type(content_type_id),
FOREIGN KEY(author_artist_id) REFERENCES Author_or_Artist(author_artist_id),
FOREIGN KEY(genre_id) REFERENCES Genre(genre_id),
FOREIGN KEY(medium_type_id) REFERENCES Medium_type(medium_type_id)
	);
CREATE SEQUENCE content_seq START WITH 1;
CREATE TABLE Rent(
rental_id DECIMAL(12) NOT NULL PRIMARY KEY,
ISBN_id DECIMAL(13) NOT NULL,
account_id DECIMAL(12) NOT NULL,
FOREIGN KEY(account_id) REFERENCES Account(account_id),
FOREIGN KEY(ISBN_id) REFERENCES Content(ISBN_id)
	);
CREATE SEQUENCE rental_seq START WITH 1;

CREATE TABLE New_fine (
balance_change_id DECIMAL(12) NOT NULL PRIMARY KEY,
old_bal DECIMAL(12,2),
new_bal DECIMAL(12,2) NOT NULL,
account_id DECIMAL(12) NOT NULL,
change_date DATE NOT NULL,
FOREIGN KEY(account_id) REFERENCES Account(account_id)
	);
CREATE SEQUENCE balance_change_seq START WITH 1;

--Indexing
CREATE UNIQUE INDEX AccountBal_idIDX
ON Account_balance(account_id);
CREATE INDEX ClubAccount_idIDX
ON Club_or_Group(account_id);
CREATE INDEX ReservationClubIDX
ON Reservation(club_group_id);
CREATE INDEX ReservationRoomIDX
ON Reservation(room_id);
CREATE INDEX ContentTypeIDX
ON Content(content_type_id);
CREATE INDEX ContentGenreIDX
ON Content(genre_id);
CREATE INDEX ContentMediumIDX
ON Content(medium_type_id);
CREATE INDEX ContentAuthorIDX
ON Content(author_artist_id);
CREATE INDEX ContentNameIDX
ON Content(content_name);
CREATE INDEX AccountBalanceIDX
ON Account_balance(balance);
CREATE INDEX AccountMembeershipStartIDX
ON Account(membership_start);

--Trigger for history of fines applied to accounts
CREATE OR REPLACE FUNCTION NewFineFunction()
RETURNS TRIGGER LANGUAGE plpgsql
AS $trigfunc$
	BEGIN
	INSERT INTO New_fine(balance_change_id, old_bal, new_bal, account_id, change_date)
	VALUES (nextval('balance_change_seq'), OLD.balance, NEW.balance, NEW.account_id, current_date);
	RETURN NEW;
	END;
$trigfunc$;

CREATE TRIGGER NewFineTrigger
BEFORE UPDATE OF balance ON Account_balance
FOR EACH ROW
EXECUTE PROCEDURE NewFineFunction();
/*
--Procedure for an overdue fine applied to an account
CREATE OR REPLACE FUNCTION add_overduefee(account_id IN DECIMAL(12))
RETURNS VOID LANGUAGE plpgsql
AS
$proc$
DECLARE
	current_balance DECIMAL(6,2);
BEGIN

	INSERT INTO Account_balance(fine_id,balance,account_id)
	VALUES(nextval('account_balance_seq'),current_balance + 25.00,account_id);
	INSERT INTO overdue_fee(fine_id)
	VALUES(currval('account_balance_seq'));
END;
$proc$;

/*
SELECT *
FROM Account
JOIN Account_balance ON Account_balance.account_id = Account.account_id;
START TRANSACTION;
DO
$$ BEGIN
	EXECUTE add_overduefee(1);
	END $$;
COMMIT TRANSACTION;
ROLLBACK;
*/

--Procedure for a damaged fine applied to an account
CREATE OR REPLACE FUNCTION add_damagedfee(account_id_arg IN DECIMAL(12))
RETURNS VOID LANGUAGE plpgsql
AS
$proc$
BEGIN
	INSERT INTO Account_balance(fine_id,balance,account_id)
	VALUES(nextval('account_balance_seq'),,account_id_arg);
	INSERT INTO damaged_fee(fine_id,fine_amount)
	VALUES(currval('account_balance_seq'),50);
END;
$proc$;

--Trigger for an overdue or damaged fine applied to an account to check for non-negative balance
CREATE OR REPLACE FUNCTION valid_nonneg_balance_func()
RETURNS TRIGGER LANGUAGE plpgsql
AS $trigfunc$
BEGIN
	RAISE EXCEPTION USING MESSAGE = 'An account needs a positive balance.',
	ERRCODE = 22200;
END;
$trigfunc$;

CREATE TRIGGER nonneg_trg
BEFORE UPDATE OR INSERT ON Account_balance
FOR EACH ROW WHEN (NEW.balance < 0)
EXECUTE PROCEDURE valid_nonneg_balance_func();
*/
--Procedure for use case of adding a new account
CREATE OR REPLACE FUNCTION add_account(first_name_arg IN VARCHAR(32),last_name_arg IN VARCHAR(32))
RETURNS VOID LANGUAGE plpgsql
AS
$proc$
BEGIN
	INSERT INTO Account(account_id,first_name,last_name,membership_start)
	VALUES(nextval('account_seq'),first_name_arg,last_name_arg,current_date);
	INSERT INTO Account_balance(fine_id,balance,account_id)
	VALUES(nextval('account_balance_seq'),0.00,currval('account_seq'));
END;
$proc$;

CREATE OR REPLACE FUNCTION valid_add_account_func()
RETURNS TRIGGER LANGUAGE plpgsql
AS $trigfunc$
BEGIN
	RAISE EXCEPTION USING MESSAGE = 'An account needs a valid first and last name?',
	ERRCODE = 22222;
END;
$trigfunc$;

CREATE TRIGGER valid_add_account_trg
BEFORE UPDATE OR INSERT ON Account
FOR EACH ROW WHEN(NEW.first_name = NULL
	              AND NEW.last_name = NULL)
EXECUTE PROCEDURE valid_add_account_func();

--Procedure for adding a Club or Group
CREATE OR REPLACE FUNCTION add_club_group(club_name_arg IN VARCHAR(64),description_arg IN VARCHAR(764),
										 account_id_arg IN DECIMAL(12))
RETURNS VOID LANGUAGE plpgsql
AS
$proc$
BEGIN
	INSERT INTO Club_or_Group(club_group_id,description,club_name,account_id)
	VALUES(nextval('club_group_seq'),description_arg,club_name_arg,account_id_arg);
END;
$proc$;

--Trigger for making sure new club or group has a valid name and description
CREATE OR REPLACE FUNCTION valid_add_club_group_func()
RETURNS TRIGGER LANGUAGE plpgsql
AS $trigfunc$
BEGIN
	RAISE EXCEPTION USING MESSAGE = 'A Club or Group needs a valid name and description?',
	ERRCODE = 22223;
END;
$trigfunc$;

CREATE TRIGGER valid_add_club_group_trg
BEFORE UPDATE OR INSERT ON Club_or_Group
FOR EACH ROW WHEN(NEW.description = NULL
	              AND NEW.club_name = NULL)
EXECUTE PROCEDURE valid_add_club_group_func();

--Procedure for adding a new physical piece of literature
CREATE OR REPLACE FUNCTION add_Literature_Physical(
ISBN_id_arg IN DECIMAL(13),
title_arg IN VARCHAR(255),
author_first_name_arg IN VARCHAR(64),
author_last_name_arg IN VARCHAR(64),
genre_arg IN VARCHAR(64),
number_copies_arg IN DECIMAL(3))
RETURNS VOID LANGUAGE plpgsql
AS
$proc$
BEGIN
	INSERT INTO Content_type(content_type_id,content_type)
	VALUES(nextval('content_type_seq'),'Literature');
	INSERT INTO Literature(content_type_id)
	VALUES(currval('content_type_seq'));
	INSERT INTO Medium_type(medium_type_id,medium_type)
	VALUES(nextval('medium_type_seq'),'physical');
	INSERT INTO physical(medium_type_id)
	VALUES(currval('medium_type_seq'));
	INSERT INTO Content(ISBN_id,content_name,number_copies,content_type_id,author_artist_id,genre_id,medium_type_id)
	VALUES(ISBN_id_arg,title_arg,number_copies_arg,currval('content_type_seq'),(SELECT author_artist_id FROM Author_or_Artist WHERE
																			   Author_or_Artist.first_name = author_first_name_arg AND
																			   Author_or_Artist.last_name = author_last_name_arg),
		  (SELECT genre_id FROM Genre WHERE Genre.genre_type = genre_arg),currval('medium_type_seq'));
END;
$proc$;

--Trigger to make sure creator and genre are in the database (SAME for all new content adds)
CREATE OR REPLACE FUNCTION check_creator_genre_onFile_func()
RETURNS TRIGGER LANGUAGE plpgsql
AS $trigfunc$
BEGIN
	RAISE EXCEPTION USING MESSAGE = 'Please make sure the author, artist, and/or genre is already in the database',
	ERRCODE = 22224;
END;
$trigfunc$;

CREATE TRIGGER check_creator_genre_onFile_trg
BEFORE UPDATE OR INSERT ON Content
FOR EACH ROW WHEN(NEW.author_artist_id = NULL
	              OR NEW.genre_id = NULL)
EXECUTE PROCEDURE check_creator_genre_onFile_func();

--Procedure for adding a new digital piece of literature
CREATE OR REPLACE FUNCTION add_Literature_Digital(
ISBN_id_arg IN DECIMAL(13),
title_arg IN VARCHAR(255),
author_first_name_arg IN VARCHAR(64),
author_last_name_arg IN VARCHAR(64),
genre_arg IN VARCHAR(64),
number_copies_arg IN DECIMAL(3))
RETURNS VOID LANGUAGE plpgsql
AS
$proc$
BEGIN
	INSERT INTO Content_type(content_type_id,content_type)
	VALUES(nextval('content_type_seq'),'Literature');
	INSERT INTO Literature(content_type_id)
	VALUES(currval('content_type_seq'));
	INSERT INTO Medium_type(medium_type_id,medium_type)
	VALUES(nextval('medium_type_seq'),'digital');
	INSERT INTO digital(medium_type_id)
	VALUES(currval('medium_type_seq'));
	INSERT INTO Content(ISBN_id,content_name,number_copies,content_type_id,author_artist_id,genre_id,medium_type_id)
	VALUES(ISBN_id_arg,title_arg,number_copies_arg,currval('content_type_seq'),(SELECT author_artist_id FROM Author_or_Artist WHERE
																			   Author_or_Artist.first_name = author_first_name_arg AND
																			   Author_or_Artist.last_name = author_last_name_arg),
		  (SELECT genre_id FROM Genre WHERE Genre.genre_type = genre_arg),currval('medium_type_seq'));
END;
$proc$;

--Procedure for adding a new physical music item
CREATE OR REPLACE FUNCTION add_Music_Physical(
title_arg IN VARCHAR(255),
artist_or_band_arg IN VARCHAR(64),
genre_arg IN VARCHAR(64),
number_copies_arg IN DECIMAL(3))
RETURNS VOID LANGUAGE plpgsql
AS
$proc$
BEGIN
	INSERT INTO Content_type(content_type_id,content_type)
	VALUES(nextval('content_type_seq'),'Music');
	INSERT INTO Music(content_type_id)
	VALUES(currval('content_type_seq'));
	INSERT INTO Medium_type(medium_type_id,medium_type)
	VALUES(nextval('medium_type_seq'),'physical');
	INSERT INTO physical(medium_type_id)
	VALUES(currval('medium_type_seq'));
	INSERT INTO Content(ISBN_id,content_name,number_copies,content_type_id,author_artist_id,genre_id,medium_type_id)
	VALUES(nextval('content_seq'),title_arg,number_copies_arg,currval('content_type_seq'),(SELECT author_artist_id FROM Author_or_Artist WHERE
																			   Author_or_Artist.last_name = artist_or_band_arg),
		  (SELECT genre_id FROM Genre WHERE Genre.genre_type = genre_arg),currval('medium_type_seq'));
END;
$proc$;

--Procedure for adding a new digital music item
CREATE OR REPLACE FUNCTION add_Music_Digital(
title_arg IN VARCHAR(255),
artist_or_band_arg IN VARCHAR(64),
genre_arg IN VARCHAR(64),
number_copies_arg IN DECIMAL(3))
RETURNS VOID LANGUAGE plpgsql
AS
$proc$
BEGIN
	INSERT INTO Content_type(content_type_id,content_type)
	VALUES(nextval('content_type_seq'),'Music');
	INSERT INTO Music(content_type_id)
	VALUES(currval('content_type_seq'));
	INSERT INTO Medium_type(medium_type_id,medium_type)
	VALUES(nextval('medium_type_seq'),'digital');
	INSERT INTO digital(medium_type_id)
	VALUES(currval('medium_type_seq'));
	INSERT INTO Content(ISBN_id,content_name,number_copies,content_type_id,author_artist_id,genre_id,medium_type_id)
	VALUES(nextval('content_seq'),title_arg,number_copies_arg,currval('content_type_seq'),(SELECT author_artist_id FROM Author_or_Artist WHERE
																			   Author_or_Artist.last_name = artist_or_band_arg),
		  (SELECT genre_id FROM Genre WHERE Genre.genre_type = genre_arg),currval('medium_type_seq'));
END;
$proc$;

--Procedure for adding a new physical game item
CREATE OR REPLACE FUNCTION add_Game_Physical(
title_arg IN VARCHAR(255),
creator_arg IN VARCHAR(64),
genre_arg IN VARCHAR(64),
number_copies_arg IN DECIMAL(3))
RETURNS VOID LANGUAGE plpgsql
AS
$proc$
BEGIN
	INSERT INTO Content_type(content_type_id,content_type)
	VALUES(nextval('content_type_seq'),'Game');
	INSERT INTO Games(content_type_id)
	VALUES(currval('content_type_seq'));
	INSERT INTO Medium_type(medium_type_id,medium_type)
	VALUES(nextval('medium_type_seq'),'physical');
	INSERT INTO physical(medium_type_id)
	VALUES(currval('medium_type_seq'));
	INSERT INTO Content(ISBN_id,content_name,number_copies,content_type_id,author_artist_id,genre_id,medium_type_id)
	VALUES(nextval('content_seq'),title_arg,number_copies_arg,currval('content_type_seq'),(SELECT author_artist_id FROM Author_or_Artist WHERE
																			   Author_or_Artist.last_name = creator_arg),
		  (SELECT genre_id FROM Genre WHERE Genre.genre_type = genre_arg),currval('medium_type_seq'));
END;
$proc$;

--Procedure for adding a new digital game item
CREATE OR REPLACE FUNCTION add_Game_Digital(
title_arg IN VARCHAR(255),
creator_arg IN VARCHAR(64),
genre_arg IN VARCHAR(64),
number_copies_arg IN DECIMAL(3))
RETURNS VOID LANGUAGE plpgsql
AS
$proc$
BEGIN
	INSERT INTO Content_type(content_type_id,content_type)
	VALUES(nextval('content_type_seq'),'Game');
	INSERT INTO Games(content_type_id)
	VALUES(currval('content_type_seq'));
	INSERT INTO Medium_type(medium_type_id,medium_type)
	VALUES(nextval('medium_type_seq'),'digital');
	INSERT INTO digital(medium_type_id)
	VALUES(currval('medium_type_seq'));
	INSERT INTO Content(ISBN_id,content_name,number_copies,content_type_id,author_artist_id,genre_id,medium_type_id)
	VALUES(nextval('content_seq'),title_arg,number_copies_arg,currval('content_type_seq'),(SELECT author_artist_id FROM Author_or_Artist WHERE
																			   Author_or_Artist.last_name = creator_arg),
		  (SELECT genre_id FROM Genre WHERE Genre.genre_type = genre_arg),currval('medium_type_seq'));
END;
$proc$;

--Procedure for renting a piece of content
CREATE OR REPLACE FUNCTION Rent(account_id_arg IN DECIMAL(12), ISBN_id_arg IN DECIMAL(13))
RETURNS VOID LANGUAGE plpgsql
AS
$proc$
BEGIN
	INSERT INTO Rent(rental_id,account_id,ISBN_id)
	VALUES(nextval('rental_seq'),account_id_arg,ISBN_id_arg);
END;
$proc$;

--Trigger to make sure both arguements are valid
CREATE OR REPLACE FUNCTION valid_rental_func()
RETURNS TRIGGER LANGUAGE plpgsql
AS $trigfunc$
BEGIN
	RAISE EXCEPTION USING MESSAGE = 'Please put both an account_id and ISBN_id.',
	ERRCODE = 22225;
END;
$trigfunc$;

CREATE TRIGGER valid_rental_trg
BEFORE UPDATE OR INSERT ON Rent
FOR EACH ROW WHEN(NEW.account_id = NULL
	              OR NEW.ISBN_id = NULL)
EXECUTE PROCEDURE valid_rental_func();

--Procedure for renting a room
CREATE OR REPLACE FUNCTION Reservation(club_group_id_arg IN DECIMAL(12),room_id_arg IN DECIMAL(12),
									  date_arg IN VARCHAR(24))
RETURNS VOID LANGUAGE plpgsql
AS
$proc$
BEGIN
	INSERT INTO Reservation(reservation_id,club_group_id,room_id,reservation_date)
	VALUES(nextval('reservation_seq'),club_group_id_arg,room_id_arg,CAST(date_arg AS DATE));
END;
$proc$;

--Trigger to make sure reservation has valid date
CREATE OR REPLACE FUNCTION valid_date_func()
RETURNS TRIGGER LANGUAGE plpgsql
AS $trigfunc$
BEGIN
	RAISE EXCEPTION USING MESSAGE = 'Reservation Needs a Date.',
	ERRCODE = 22226;
END;
$trigfunc$;

CREATE TRIGGER valid_date_trg
BEFORE UPDATE OR INSERT ON Reservation
FOR EACH ROW WHEN(NEW.reservation_date = NULL)
EXECUTE PROCEDURE valid_date_func();

--NOW STARTING MANUAL INSERTION
--INSERTING GENRES
INSERT INTO Genre(genre_id,genre_type)
VALUES(nextval('genre_seq'),'Fantasy');
INSERT INTO Genre(genre_id,genre_type)
VALUES(nextval('genre_seq'),'SCI-FI');
INSERT INTO Genre(genre_id,genre_type)
VALUES(nextval('genre_seq'),'Grunge');
INSERT INTO Genre(genre_id,genre_type)
VALUES(nextval('genre_seq'),'Fun');
INSERT INTO Genre(genre_id,genre_type)
VALUES(nextval('genre_seq'),'Educational');
INSERT INTO Genre(genre_id,genre_type)
VALUES(nextval('genre_seq'),'Alternative');
--INSERTING AUTHORS OR ARTISTS   'You Wouldnt Want to be a Viking Explorer!'
INSERT INTO Author_or_Artist(author_artist_id,first_name,last_name)
VALUES(nextval('author_artist_seq'),'J.K.','Rowling');
INSERT INTO Author_or_Artist(author_artist_id,first_name,last_name)
VALUES(nextval('author_artist_seq'),'Orson','Card');
INSERT INTO Author_or_Artist(author_artist_id,first_name,last_name)
VALUES(nextval('author_artist_seq'),null,'Red Hot Chili Peppers');
INSERT INTO Author_or_Artist(author_artist_id,first_name,last_name)
VALUES(nextval('author_artist_seq'),null,'Nirvana');
INSERT INTO Author_or_Artist(author_artist_id,first_name,last_name)
VALUES(nextval('author_artist_seq'),null,'Pearl Jam');
INSERT INTO Author_or_Artist(author_artist_id,first_name,last_name)
VALUES(nextval('author_artist_seq'),null,'Namco');
INSERT INTO Author_or_Artist(author_artist_id,first_name,last_name)
VALUES(nextval('author_artist_seq'),null,'Hasbro');
--INSERTING ROOMS
INSERT INTO Room(room_id)
VALUES(nextval('room_seq'));
INSERT INTO Room(room_id)
VALUES(nextval('room_seq'));
INSERT INTO Room(room_id)
VALUES(nextval('room_seq'));
INSERT INTO Room(room_id)
VALUES(nextval('room_seq'));
INSERT INTO Room(room_id)
VALUES(nextval('room_seq'));
INSERT INTO Room(room_id)
VALUES(nextval('room_seq'));
--INSERT INTO Account_balance(nextval('account_balance_seq'),)
--NOW INSERTING BY TRANSACTION
--USE CASE: adding account
START TRANSACTION;
DO
$$ BEGIN
	EXECUTE add_account('Tyler','Auger');
	END $$;
COMMIT TRANSACTION;
--The rest of the accounts for the examples
START TRANSACTION;
DO
$$ BEGIN
	EXECUTE add_account('John','Doe');
	END $$;
COMMIT TRANSACTION;
START TRANSACTION;
DO
$$ BEGIN
	EXECUTE add_account('Jane','Doe');
	END $$;
COMMIT TRANSACTION;
START TRANSACTION;
DO
$$ BEGIN
	EXECUTE add_account('SpongeBob','SquarePants');
	END $$;
COMMIT TRANSACTION;
START TRANSACTION;
DO
$$ BEGIN
	EXECUTE add_account('Patrick','Star');
	END $$;
COMMIT TRANSACTION;
START TRANSACTION;
DO
$$ BEGIN
	EXECUTE add_account('Squidward','Tentacles');
	END $$;
COMMIT TRANSACTION;
START TRANSACTION;
DO
$$ BEGIN
	EXECUTE add_account('Eugene','Crabs');
	END $$;
COMMIT TRANSACTION;
START TRANSACTION;
DO
$$ BEGIN
	EXECUTE add_account('Plankton','Evil');
	END $$;
COMMIT TRANSACTION;
START TRANSACTION;
DO
$$ BEGIN
	EXECUTE add_account('Mermaid','Man');
	END $$;
COMMIT TRANSACTION;
START TRANSACTION;
DO
$$ BEGIN
	EXECUTE add_account('Barnacle','Boy');
	END $$;
COMMIT TRANSACTION;
START TRANSACTION;
DO
$$ BEGIN
	EXECUTE add_account('Sandy','Cheeks');
	END $$;
COMMIT TRANSACTION;

/*TESTS**
SELECT *
FROM Account;
SELECT *
FROM Account_balance;
SELECT *
FROM Genre;
SELECT *
FROM Author_or_Artist;
SELECT *
FROM Room
**GOOD**/

--Adding Content
START TRANSACTION;
DO
$$ BEGIN
	EXECUTE add_Literature_Physical(0312932081,'Enders Game','Orson','Card','SCI-FI',2);
	END $$;
COMMIT TRANSACTION;
START TRANSACTION;
DO
$$ BEGIN
	EXECUTE add_Literature_Physical(0312850565,'Xenocide','Orson','Card','SCI-FI',1);
	END $$;
COMMIT TRANSACTION;
START TRANSACTION;
DO
$$ BEGIN
	EXECUTE add_Literature_Physical(9780812550757,'Speaker for the Dead','Orson','Card','SCI-FI',1);
	END $$;
COMMIT TRANSACTION;
START TRANSACTION;
DO
$$ BEGIN
	EXECUTE add_Literature_Physical(0312893955,'Children of the Mind','Orson','Card','SCI-FI',2);
	END $$;
COMMIT TRANSACTION;
START TRANSACTION;
DO
$$ BEGIN
	EXECUTE add_Literature_Digital(9780590353403,'Harry Potter and the Sorcerors Stone','J.K.','Rowling','Fantasy',1);
	END $$;
COMMIT TRANSACTION;
START TRANSACTION;
DO
$$ BEGIN
	EXECUTE add_Literature_Digital(9780590872539,'Harry Potter and the Chamber of Secrets','J.K.','Rowling','Fantasy',1);
	END $$;
COMMIT TRANSACTION;
START TRANSACTION;
DO
$$ BEGIN
	EXECUTE add_Literature_Digital(9789176625389,'Harry Potter and the Prisoner of Azkaban','J.K.','Rowling','Fantasy',1);
	END $$;
COMMIT TRANSACTION;
START TRANSACTION;
DO
$$ BEGIN
	EXECUTE add_Literature_Digital(07475426423,'Harry Potter and the Goblet of Fire','J.K.','Rowling','Fantasy',1);
	END $$;
COMMIT TRANSACTION;
START TRANSACTION;
DO
$$ BEGIN
	EXECUTE add_Literature_Digital(7729035340,'Harry Potter and the Order of the Phoenix','J.K.','Rowling','Fantasy',1);
	END $$;
COMMIT TRANSACTION;
START TRANSACTION;
DO
$$ BEGIN
	EXECUTE add_Literature_Digital(0819035773,'Harry Potter and the Half-Blood Prince','J.K.','Rowling','Fantasy',1);
	END $$;
COMMIT TRANSACTION;
START TRANSACTION;
DO
$$ BEGIN
	EXECUTE add_Literature_Digital(2729036545,'Harry Potter and the Deathly Hallows','J.K.','Rowling','Fantasy',1);
	END $$;
COMMIT TRANSACTION;


/* *********QUESTION QUERY AND TEST SUCCESSFUL***************
SELECT content_name,first_name,last_name,ISBN_id,content_type,medium_type,genre_type
FROM Content
JOIN Author_or_Artist ON Author_or_Artist.author_artist_id = Content.author_artist_id
JOIN Content_type ON Content_type.content_type_id = Content.content_type_id
JOIN Medium_type ON Medium_type.medium_type_id = Content.medium_type_id
JOIN Genre ON Genre.genre_id = Content.genre_id;
*/
START TRANSACTION;
DO
$$ BEGIN
	EXECUTE add_Music_Physical('Blood Sugar Sex Magic','Red Hot Chili Peppers','Alternative',2);
	END $$;
COMMIT TRANSACTION;
START TRANSACTION;
DO
$$ BEGIN
	EXECUTE add_Music_Physical('Nevermind','Nirvana','Grunge',4);
	END $$;
COMMIT TRANSACTION;
START TRANSACTION;
DO
$$ BEGIN
	EXECUTE add_Music_Digital('Ten','Pearl Jam','Grunge',1);
	END $$;
COMMIT TRANSACTION;
START TRANSACTION;
DO
$$ BEGIN
	EXECUTE add_Game_Physical('Connect4','Hasbro','Educational',6);
	END $$;
COMMIT TRANSACTION;
START TRANSACTION;
DO
$$ BEGIN
	EXECUTE add_Game_Digital('Ms. PacMan','Namco','Fun',1);
	END $$;
COMMIT TRANSACTION;
/*
SELECT *
FROM Author_or_Artist;

SELECT *
FROM Genre;

SELECT *
FROM Room;

SELECT *
FROM Account
JOIN Account_balance ON Account_balance.account_id = Account.account_id;
ROLLBACK;*/

/* *********QUERY AND TEST SUCCESSFUL***************
SELECT content_name,first_name,last_name,ISBN_id,content_type,medium_type,genre_type
FROM Content
JOIN Author_or_Artist ON Author_or_Artist.author_artist_id = Content.author_artist_id
JOIN Content_type ON Content_type.content_type_id = Content.content_type_id
JOIN Medium_type ON Medium_type.medium_type_id = Content.medium_type_id
JOIN Genre ON Genre.genre_id = Content.genre_id;
*/

--Adding Rentals -  for future 2nd history table.
START TRANSACTION;
DO
$$ BEGIN
	EXECUTE Rent(1,312932081);
	END $$;
COMMIT TRANSACTION;
START TRANSACTION;
DO
$$ BEGIN
	EXECUTE Rent(2,9789176625389);
	END $$;
COMMIT TRANSACTION;
START TRANSACTION;
DO
$$ BEGIN
	EXECUTE Rent(5,9780812550757);
	END $$;
COMMIT TRANSACTION;
START TRANSACTION;
DO
$$ BEGIN
	EXECUTE Rent(7,5);
	END $$;
COMMIT TRANSACTION;
START TRANSACTION;
DO
$$ BEGIN
	EXECUTE Rent(5,1);
	END $$;
COMMIT TRANSACTION;
START TRANSACTION;
DO
$$ BEGIN
	EXECUTE Rent(5,9789176625389);
	END $$;
COMMIT TRANSACTION;
START TRANSACTION;
DO
$$ BEGIN
	EXECUTE Rent(4,312932081);
	END $$;
COMMIT TRANSACTION;
START TRANSACTION;
DO
$$ BEGIN
	EXECUTE Rent(10,312850565);
	END $$;
COMMIT TRANSACTION;
START TRANSACTION;
DO
$$ BEGIN
	EXECUTE Rent(8,3);
	END $$;
COMMIT TRANSACTION;
START TRANSACTION;
DO
$$ BEGIN
	EXECUTE Rent(8,2);
	END $$;
COMMIT TRANSACTION;
/*

SELECT *
FROM Rent;

*/
--Adding Clubs And Groups
START TRANSACTION;
DO
$$
BEGIN
EXECUTE add_club_group('Nerdsquad','This club is all about people getting together
and talking about things that are considered "Nerdy"',1);
END
$$;
COMMIT TRANSACTION;
START TRANSACTION;
DO
$$
BEGIN
EXECUTE add_club_group('Aviators Club','This club is all about people getting together
and talking about planes and other aerospace topics',8);
END
$$;
COMMIT TRANSACTION;
START TRANSACTION;
DO
$$
BEGIN
EXECUTE add_club_group('Boys and Girls Club','Get ready for fun! This club is all about people getting together
and talking and interacting with people their age',7);
END
$$;
COMMIT TRANSACTION;
START TRANSACTION;
DO
$$
BEGIN
EXECUTE add_club_group('Book of the Month Club','Love Reading? This club gives you a new book to read and talk about
					   with other people.',1);
END
$$;
COMMIT TRANSACTION;
START TRANSACTION;
DO
$$
BEGIN
EXECUTE add_club_group('Food Club','Love to cook? This is about getting together with other members of your community and sharing
					   recipes and tricks.',5);
END
$$;
COMMIT TRANSACTION;
START TRANSACTION;
DO
$$
BEGIN
EXECUTE add_club_group('Gardening Club','This club is for gardening fanatics to get together and share tips and tricks.',3);
END
$$;
COMMIT TRANSACTION;
START TRANSACTION;
DO
$$
BEGIN
EXECUTE add_club_group('Math Club','Its all about numbers and stuff!',10);
END
$$;
COMMIT TRANSACTION;
START TRANSACTION;
DO
$$
BEGIN
EXECUTE add_club_group('Science Club','Its about science yall!',6);
END
$$;
COMMIT TRANSACTION;
START TRANSACTION;
DO
$$
BEGIN
EXECUTE add_club_group('Geology Club','Geology is a real science!',9);
END
$$;
COMMIT TRANSACTION;
START TRANSACTION;
DO
$$
BEGIN
EXECUTE add_club_group('Lacrosse Club','Lax bros for life!',1);
END
$$;
COMMIT TRANSACTION;
/*
SELECT *
FROM Club_or_Group;

ROLLBACK;
*/
--Room Reservations
START TRANSACTION;
DO
$$
BEGIN
EXECUTE Reservation(1,1,'4-APR-2021');
END
$$;
COMMIT TRANSACTION;
START TRANSACTION;
DO
$$
BEGIN
EXECUTE Reservation(3,6,'1-APR-2021');
END
$$;
COMMIT TRANSACTION;
START TRANSACTION;
DO
$$
BEGIN
EXECUTE Reservation(2,5,'9-APR-2021');
END
$$;
COMMIT TRANSACTION;
START TRANSACTION;
DO
$$
BEGIN
EXECUTE Reservation(8,2,'16-APR-2021');
END
$$;
COMMIT TRANSACTION;
START TRANSACTION;
DO
$$
BEGIN
EXECUTE Reservation(4,1,'13-APR-2021');
END
$$;
COMMIT TRANSACTION;
START TRANSACTION;
DO
$$
BEGIN
EXECUTE Reservation(5,3,'11-APR-2021');
END
$$;
COMMIT TRANSACTION;
START TRANSACTION;
DO
$$
BEGIN
EXECUTE Reservation(10,6,'26-APR-2021');
END
$$;
COMMIT TRANSACTION;
START TRANSACTION;
DO
$$
BEGIN
EXECUTE Reservation(9,1,'13-MAR-2021');
END
$$;
COMMIT TRANSACTION;
START TRANSACTION;
DO
$$
BEGIN
EXECUTE Reservation(1,1,'17-MAR-2021');
END
$$;
COMMIT TRANSACTION;
START TRANSACTION;
DO
$$
BEGIN
EXECUTE Reservation(4,2,'18-MAY-2021');
END
$$;
COMMIT TRANSACTION;
/*
SELECT *
FROM Account;
SELECT *
FROM Account_balance
SELECT *
FROM overdue_fee;
SELECT *
FROM damaged_fee;
SELECT *
FROM Reservation;
SELECT *
FROM Club_or_Group;
SELECT *
FROM Rent;
SELECT content_name,first_name,last_name,number_copies,ISBN_id,content_type,medium_type,genre_type
FROM Content
JOIN Author_or_Artist ON Author_or_Artist.author_artist_id = Content.author_artist_id
JOIN Content_type ON Content_type.content_type_id = Content.content_type_id
JOIN Medium_type ON Medium_type.medium_type_id = Content.medium_type_id
JOIN Genre ON Genre.genre_id = Content.genre_id;
*/

--Q1
--Which accounts that were created in February 2021 have a balance over $50, and how many fines do they have
-- To do this, I had populated some accounts with one or multiple $25 fines repeating the following query with
SELECT first_name,last_name,balance,COUNT(balance_change_id) AS number_of_fines
FROM Account
JOIN Account_balance ON Account_balance.account_id = Account.account_id
JOIN New_fine ON New_fine.account_id = Account_balance.account_id
WHERE Account.membership_start BETWEEN CAST('1-Feb-2021' as DATE) AND CAST('28-Feb-2021' as DATE)
GROUP BY first_name,last_name,balance;

--Q2
--“How many pieces of content are Literature and Physical?”
SELECT Count(*) AS Total_Physical_Literature_collection
FROM Content
JOIN Content_type ON Content_type.content_type_id = Content.content_type_id
JOIN Literature ON Literature.content_type_id = Content_type.content_type_id
JOIN Medium_type ON Medium_type.medium_type_id = Content.medium_type_id
JOIN Physical ON Physical.medium_type_id = Medium_type.medium_type_id;

--Q3
--"I want to browse all available content!"
SELECT content_name,first_name,last_name,number_copies,ISBN_id,content_type,medium_type,genre_type
FROM Content
JOIN Author_or_Artist ON Author_or_Artist.author_artist_id = Content.author_artist_id
JOIN Content_type ON Content_type.content_type_id = Content.content_type_id
JOIN Medium_type ON Medium_type.medium_type_id = Content.medium_type_id
JOIN Genre ON Genre.genre_id = Content.genre_id;

SELECT first_name, last_name, COUNT(Rent.account_id) AS number_of_rentals
FROM Rent
JOIN Account ON Account.Account_id = Rent.account_id
GROUP BY first_name, last_name;

SELECT COUNT(*) FILTER(WHERE genre_type = 'Fantasy') AS Fantasy, COUNT(*) FILTER(WHERE genre_type = 'SCI-FI') AS SCI_FI,
COUNT(*) FILTER(WHERE genre_type = 'Grunge') AS Grunge, COUNT(*) FILTER(WHERE genre_type = 'Fun') AS Fun,
COUNT(*) FILTER(WHERE genre_type = 'Educational') AS Educational, COUNT(*) FILTER(WHERE genre_type = 'Alternative') AS Alternative
FROM Genre
JOIN Content ON Content.genre_id = Genre.genre_id;


SELECT Content.content_name, COUNT(rental_id) AS number_of_rentals
FROM Rent
JOIN Content ON Content.ISBN_id = Rent.ISBN_id
GROUP BY Content.content_name
ORDER BY number_of_rentals DESC;




SELECT *
FROM Rent;
------------------------------------------------------------------------------------------------------------------------------------------

/*
EXAMPLE OF NewFineTrigger TRIGGER
SELECT *
FROM Account_balance;
Update Account_balance
SET balance = balance + 25
WHERE account_id = 8;
ROLLBACK;
SELECT *
FROM New_fine;

--Transaction for new account test
START TRANSACTION;
DO
$$
BEGIN
EXECUTE add_account('Tyler','Auger');
END
$$;
COMMIT TRANSACTION;

SELECT *
FROM Account;
SELECT *
FROM Account_balance;

--Transaction for new Club or Group test
START TRANSACTION;
DO
$$
BEGIN
EXECUTE add_club_group('Nerdsquad','This club is all about people getting together
and talking about things that are considered "Nerdy"',2);
END
$$;
COMMIT TRANSACTION;

SELECT *
FROM Club_or_Group;


*/



/*Procedure To Add Physical Literature with NEW AUTHOR/GENRE ROUGH DRAFT
CREATE OR REPLACE FUNCTION New_Literature_Physical(
ISBN_id IN DECIMAL(13),
title IN VARCHAR(255),
author_first_name IN VARCHAR(64),
author_last_name IN VARCHAR(64),
genre IN VARCHAR(64),
number_copies IN DECIMAL(3))
RETURNS VOID
AS
$proc$
**might need to DECLARE passed arguements? could be the problem?**
BEGIN
	INSERT INTO Content_type(content_type_id,content_type)
	VALUES(nextval('content_type_seq'),'Literature');
	INSERT INTO Literature(content_type_id)
	VALUES(currval('content_type_seq'));
	INSERT INTO Medium_type(medium_type_id,medium_type)
	VALUES(nextval('medium_type_seq'),'physical');
	INSERT INTO physical(medium_type_id)
	VALUES(currval('medium_type_seq'));


	     IF genre != (SELECT genre_type FROM Genre)
		 	THEN
			INSERT INTO Genre(genre_id,genre_type)
			VALUES(nextval('genre_seq'),genre);
		 END IF;

		 IF author_first_name != (SELECT first_name FROM Author_or_Artist)
		 AND author_last_name != (SELECT last_name FROM Author_or_Artist)
		 	THEN
		 	INSERT INTO Author_or_Artist(author_artist_id,first_name,last_name)
		 	VALUES(nextval('author_artist_seq'),author_first_name,author_last_name);
		 END IF;

	INSERT INTO Content(ISBN_id,content_name,number_copies,content_type_id,author_artist_id,genre_id,medium_type_id)
	VALUES(ISBN_id,title,number_copies,currval('content_type_seq'),(SELECT author_artist_id FROM Author_or_Artist
																   WHERE Author_or_Artist.first_name = author_first_name
																   AND Author_or_Artist.last_name = author_last_name),
		  (SELECT genre_id FROM Genre WHERE Genre.genre_type = genre),currval('medium_type_seq'));

END;
$proc$ LANGUAGE plpgsql

ROLLBACK;

START TRANSACTION;
DO
$$BEGIN
	EXECUTE New_Literature_Physical(9780345339706,'Lord of the Rings: Fellowship of the Ring',
								   'J.R.R.', 'Tolkein','Fantasy',3);
END$$;
COMMIT TRANSACTION;
*/
